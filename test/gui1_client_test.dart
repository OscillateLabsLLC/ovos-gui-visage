import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/protocol/gui1_client.dart';
import 'package:ovos_gui_visage/protocol/gui_client.dart';
import 'package:ovos_gui_visage/protocol/gui_link.dart';

import 'faults.dart';
import 'recording_bus.dart';

const _welcome = {'type': 'welcome', 'protocol': 'ovos-gui-1', 'version': 1, 'session_id': 'default', 'server': 'fake/1'};
const _snapshot = {'type': 'snapshot', 'session_id': 'default', 'stack': <Object>[]};
final _url = Uri.parse('ws://127.0.0.1:1/gui1');

/// A scripted adapter: [sent] holds what the client wrote, [serve] answers.
class FakeSocket implements Gui1Socket {
  FakeSocket({this.refuse = false});

  final bool refuse;
  final sent = <Json>[];
  final _frames = StreamController<dynamic>();
  bool closed = false;

  void serve(Object frame) => _frames.add(frame is String ? frame : jsonEncode(frame));

  void hangUp() => _frames.close();

  @override
  Future<void> get ready => refuse ? Future.error(const SocketException('refused')) : Future.value();

  @override
  Stream<dynamic> get stream => _frames.stream;

  @override
  void add(String text) => sent.add(jsonDecode(text) as Json);

  @override
  Future<void> close() async {
    closed = true;
    if (!_frames.isClosed) await _frames.close();
  }
}

class Harness {
  Harness(this.socket, {Duration timeout = const Duration(milliseconds: 200)}) {
    client = Gui1Client(
      url: _url,
      connector: (_) => socket,
      timeout: timeout,
      onFrame: frames.add,
      onStatus: status.add,
      log: logs.add,
    );
  }

  final FakeSocket socket;
  late final Gui1Client client;
  final frames = <Gui1Frame>[];
  final status = <bool>[];
  final logs = <String>[];
}

/// A legacy client that records how it was driven instead of negotiating on the bus.
class FakeLegacy extends GuiClient {
  FakeLegacy() : super(bus: RecordingBus(), guiId: 't', onMessage: (_) {}, onStatus: (_) {});

  var started = 0;
  var attempts = 0;
  final sends = <Json>[];

  @override
  void start() => started++;

  @override
  Future<void> connectOnce() async => attempts++;

  @override
  bool send(Json message) {
    sends.add(message);
    return true;
  }
}

void main() {
  group('handshake', () {
    test('sends hello first and is welcomed; frames then arrive typed', () async {
      final h = Harness(FakeSocket());
      final connecting = h.client.connect();
      await pumpEventQueue();
      expect(h.socket.sent, [helloFrame()]);
      h.socket.serve(_welcome);
      expect(await connecting, isTrue);
      final listening = h.client.listen();
      h.socket
        ..serve(_snapshot)
        ..serve({'type': 'idle'})
        ..hangUp();
      await listening;
      expect(h.frames.map((f) => f.runtimeType), [Gui1Snapshot, Gui1Idle]);
      expect(h.status, [true, false]);
    });

    test('an error frame, a wrong session and a silent server all mean unavailable, with the socket closed', () async {
      for (final (answer, reason) in [
        ({'type': 'error', 'reason': "unsupported protocol 'x'"}, "error: unsupported protocol 'x'"),
        ({..._welcome, 'session_id': 'kitchen'}, 'session kitchen'),
        ({'type': 'idle'}, 'first frame was not welcome'),
        (null, 'TimeoutException'),
      ]) {
        final h = Harness(FakeSocket(), timeout: const Duration(milliseconds: 50));
        final connecting = h.client.connect();
        await pumpEventQueue();
        if (answer != null) h.socket.serve(answer);
        expect(await connecting, isFalse, reason: reason);
        expect(h.socket.closed, isTrue, reason: reason);
        expect(h.logs.single, contains(reason));
        expect(h.status, isEmpty);
      }
    });

    test('a refused connection is unavailable at once', () async {
      final h = Harness(FakeSocket(refuse: true));
      expect(await h.client.connect(), isFalse);
      expect(h.logs.single, contains('refused'));
    });

    test('a frame that will not parse is reported with its payload and the socket stays', () async {
      final h = Harness(FakeSocket());
      final connecting = h.client.connect();
      await pumpEventQueue();
      h.socket.serve(_welcome);
      await connecting;
      final faults = await collectFaults(() async {
        final listening = h.client.listen();
        h.socket
          ..serve('{"type": "hologram"}')
          ..serve('not json')
          ..serve({'type': 'idle'})
          ..hangUp();
        await listening;
      });
      expect([for (final f in faults) f.context?.toDescription()], [contains('hologram'), contains('not json')]);
      expect(h.frames.single, isA<Gui1Idle>());
    });
  });

  group('a real websocket', () {
    test('the probe completes against a local server and a closed port fails fast', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final hellos = <Object?>[];
      server.listen((request) async {
        final ws = await WebSocketTransformer.upgrade(request);
        ws.listen((m) {
          hellos.add(jsonDecode(m as String));
          ws.add(jsonEncode(_welcome));
          ws.add(jsonEncode(_snapshot));
        });
      });
      final frames = <Gui1Frame>[];
      final client = Gui1Client(url: Uri.parse('ws://127.0.0.1:${server.port}/gui1'), onFrame: frames.add, onStatus: (_) {});
      expect(await client.connect(), isTrue);
      unawaited(client.listen());
      await Future.delayed(const Duration(milliseconds: 100));
      expect(hellos, [helloFrame()]);
      expect(frames.single, isA<Gui1Snapshot>());
      await client.stop();
      final port = server.port;
      await server.close(force: true);

      final watch = Stopwatch()..start();
      final refused = Gui1Client(url: Uri.parse('ws://127.0.0.1:$port/gui1'), onFrame: (_) {}, onStatus: (_) {});
      expect(await refused.connect(), isFalse);
      expect(watch.elapsed, lessThan(welcomeTimeout));
    });
  });

  group('protocol selection', () {
    GuiLink link(WireProtocol mode, FakeSocket socket, FakeLegacy legacy, List<String> logs, [RecordingBus? bus]) => GuiLink(
      mode: mode,
      legacy: legacy,
      gui1: Gui1Client(url: _url, connector: (_) => socket, onFrame: (_) {}, onStatus: (_) {}, log: logs.add),
      bus: bus ?? RecordingBus(),
      log: logs.add,
    );

    Future<GuiLink> welcomed(FakeSocket socket, FakeLegacy legacy, List<String> logs, [RecordingBus? bus]) async {
      final l = link(WireProtocol.auto, socket, legacy, logs, bus)..start();
      await pumpEventQueue();
      socket.serve(_welcome);
      await pumpEventQueue();
      return l;
    }

    test('legacy starts the legacy client as before and never probes', () {
      final legacy = FakeLegacy();
      final socket = FakeSocket();
      final logs = <String>[];
      final l = link(WireProtocol.legacy, socket, legacy, logs)..start();
      expect([legacy.started, socket.sent], [1, isEmpty]);
      expect(l.title.value, 'Protocol: legacy');
      expect(logs, ['GUI protocol (WireProtocol.legacy): legacy']);
    });

    test('auto falls back to legacy for this connection when the probe is refused', () async {
      final legacy = FakeLegacy();
      final logs = <String>[];
      final l = link(WireProtocol.auto, FakeSocket(refuse: true), legacy, logs);
      expect(l.title.value, 'Protocol: detecting…');
      l.start();
      await pumpEventQueue();
      expect([legacy.started, legacy.attempts], [0, 1]);
      expect([l.chosen, l.title.value], [ChosenProtocol.legacy, 'Protocol: legacy']);
      expect(l.send({'type': 'x'}), isTrue);
      expect(legacy.sends, [
        {'type': 'x'},
      ]);
      await l.stop();
    });

    test('auto takes GUI-1 when welcomed, and sends nothing over the GUI-1 socket', () async {
      final legacy = FakeLegacy();
      final socket = FakeSocket();
      final logs = <String>[];
      final l = await welcomed(socket, legacy, logs);
      expect([l.chosen, l.title.value], [ChosenProtocol.gui1, 'Protocol: GUI-1']);
      expect(logs.last, 'GUI protocol (WireProtocol.auto): GUI-1 at $_url');
      expect(l.send({'type': 'mycroft.session.set', 'namespace': 'x', 'data': <String, dynamic>{}}), isFalse);
      expect(logs.last, contains('no reply leg'));
      expect([legacy.attempts, legacy.sends, socket.sent], [0, isEmpty, hasLength(1)]);
      await l.stop();
    });

    test('on GUI-1 a page event goes on the core bus as legacy ovos-gui forwarded it', () async {
      final bus = RecordingBus();
      final legacy = FakeLegacy();
      final socket = FakeSocket();
      final l = await welcomed(socket, legacy, [], bus);
      final rows = [
        for (final line in File('test/fixtures/outgoing/gui1_page_events.jsonl').readAsLinesSync()) jsonDecode(line) as Json,
      ];
      expect(rows.first['note'], startsWith('written from ovos-gui source'));
      final ctx = PageContext(namespace: 'ovos.common_play', page: 'p', events: const {}, send: l.send);
      ctx.trigger('resume');
      for (final row in rows.skip(1)) {
        expect(l.send(row['sent'] as Json), isTrue);
      }
      final emitted = [
        for (final (i, e) in bus.emitted.indexed) {'type': e[0], 'data': e[1], 'context': bus.contexts[i]},
      ];
      expect(emitted, [for (final row in rows) row['bus']]);
      expect([legacy.sends, socket.sent], [isEmpty, hasLength(1)], reason: 'only the hello went to the adapter');
      await l.stop();
    });

    test('on legacy a page event still goes on the GUI socket, untouched', () {
      final bus = RecordingBus();
      final legacy = FakeLegacy();
      final l = link(WireProtocol.legacy, FakeSocket(), legacy, [], bus)..start();
      final event = guiEvent('ovos.common_play', 'resume');
      expect(l.send(event), isTrue);
      expect(
        [legacy.sends, bus.emitted],
        [
          [event],
          isEmpty,
        ],
      );
    });

    test('gui1 never falls back', () async {
      final legacy = FakeLegacy();
      final l = link(WireProtocol.gui1, FakeSocket(refuse: true), legacy, []);
      expect(l.title.value, 'Protocol: GUI-1 (connecting)');
      l.start();
      await pumpEventQueue();
      expect([legacy.started, legacy.attempts, l.chosen], [0, 0, null]);
      await l.stop();
    });
  });
}
