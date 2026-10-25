/// What Visage sends the GUI-1 adapter (WIRE.md, Client → server frames): page events as `interaction`, focus
/// requests as `focus`, never on the core bus; the legacy path is unchanged.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/protocol/gui1_outgoing.dart';
import 'package:ovos_gui_visage/protocol/gui_events.dart';
import 'package:ovos_gui_visage/protocol/gui_link.dart';

import 'faults.dart';
import 'gui1_client_test.dart' show FakeLegacy, FakeSocket, testLink, welcomedLink;

List<Json> _rows(String name) => [
  for (final line in File('test/fixtures/outgoing/$name.jsonl').readAsLinesSync())
    if (line.trim().isNotEmpty) jsonDecode(line) as Json,
];

const _demo = 'ovos-skill-gui1-demo.oscillatelabs';

void main() {
  test('the outgoing GUI-1 fixtures say they were written from WIRE.md, and each maps its page event to its frame', () {
    for (final row in [..._rows('gui1_interaction'), ..._rows('gui1_focus')]) {
      expect(row['note'], startsWith('written from WIRE.md (Client → server frames), not recorded'));
      expect(gui1FrameFor(row['sent'] as Json), row['gui1']);
    }
  });

  test('on GUI-1 a page trigger leaves on the GUI-1 socket as an interaction frame, never on the legacy socket', () async {
    final legacy = FakeLegacy();
    final socket = FakeSocket();
    final link = await welcomedLink(socket, legacy, []);
    final rows = _rows('gui1_interaction');
    for (final row in rows) {
      final sent = row['sent'] as Json;
      final ctx = PageContext(namespace: sent['namespace'] as String, page: 'p', events: const {}, send: link.send);
      ctx.trigger(sent['event_name'] as String, sent['parameters'] as Json);
    }
    expect(socket.sent.skip(1), [for (final row in rows) row['gui1']], reason: 'after the hello');
    expect(legacy.sends, isEmpty);
    await link.stop();
  });

  test('on GUI-1 a focus request leaves as a focus frame; on legacy it sends nothing, the announcer reports instead', () async {
    final socket = FakeSocket();
    final link = await welcomedLink(socket, FakeLegacy(), []);
    expect(link.requestFocus(_demo, 1), isTrue);
    expect(socket.sent.last, _rows('gui1_focus').single['gui1']);
    await link.stop();
    final legacy = FakeLegacy();
    final legacyLink = testLink(WireProtocol.legacy, FakeSocket(), legacy, [])..start();
    expect(legacyLink.requestFocus(_demo, 1), isFalse);
    expect(legacy.sends, isEmpty);
  });

  test('on GUI-1 a touch has no frame, since no frame names the active entry (F45): reported once, then logged', () async {
    final socket = FakeSocket();
    final logs = <String>[];
    final link = await welcomedLink(socket, FakeLegacy(), logs);
    final faults = await collectFaults(() async {
      expect(link.send(interactionMessage(_demo)), isFalse);
      expect(link.send(interactionMessage(_demo)), isFalse);
    });
    expect(faults.single.exceptionAsString(), contains('needs the active entry'));
    expect(logs.last, contains('needs the active entry'));
    expect(socket.sent, hasLength(1), reason: 'only the hello');
    await link.stop();
  });

  test('on GUI-1 anything but a page event has no frame and is logged, not sent', () async {
    final socket = FakeSocket();
    final logs = <String>[];
    final link = await welcomedLink(socket, FakeLegacy(), logs);
    expect(link.send({'type': 'mycroft.session.set', 'namespace': 'x', 'data': <String, dynamic>{}}), isFalse);
    expect(logs.last, contains('GUI-1 has no frame for'));
    expect(socket.sent, hasLength(1));
    await link.stop();
  });

  test('on legacy a page event still goes on the GUI socket, untouched', () {
    final legacy = FakeLegacy();
    final link = testLink(WireProtocol.legacy, FakeSocket(), legacy, [])..start();
    final event = guiEvent('ovos.common_play', 'resume');
    expect(link.send(event), isTrue);
    expect(legacy.sends, [event]);
  });

  test('a frame sent while no connection holds is refused', () {
    final socket = FakeSocket();
    final link = testLink(WireProtocol.gui1, socket, FakeLegacy(), []);
    expect(link.gui1.send(focusFrame(_demo, 0)), isFalse);
    expect(socket.sent, isEmpty);
  });
}
