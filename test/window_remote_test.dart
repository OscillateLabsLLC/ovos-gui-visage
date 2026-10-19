import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/peek.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_remote.dart';

import 'faults.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

void main() {
  const float = WindowConfig(mode: WindowMode.float, corner: Corner.bottomRight, peek: true);
  late RecordingBus bus;
  late PeekController peek;
  late List<WindowConfig> saved;
  late List<Object> applied;
  late List<String> moves;
  late WindowRemote remote;

  WindowRemote make(WindowConfig config, {WindowPersist? persist, WindowEffects? effects}) {
    peek = PeekController(enabled: config.peeks, timer: ManualTimers().create);
    final recording = WindowEffects(
      mode: (c, {required from, required expanded}) async {
        applied.add(c.mode);
        moves.add('${from.name} -> ${c.mode.name}, expanded $expanded');
      },
      visible: (v) async => applied.add(v),
    );
    return WindowRemote(bus, peek, initial: config, persist: persist ?? (c) async => saved.add(c), effects: effects ?? recording);
  }

  setUp(() {
    bus = RecordingBus();
    saved = [];
    applied = [];
    moves = [];
    remote = make(float);
  });

  test('get answers with the window state', () {
    bus.send(windowGetMessage);
    expect(bus.types, [windowStateMessage]);
    expect(bus.data(0), {
      'mode': 'float',
      'corner': 'bottomRight',
      'peek': true,
      'peekSize': 96.0,
      'expanded': false,
      'visible': true,
    });
  });

  test('set peek off expands the window, saves and announces once', () {
    bus.send(windowSetMessage, {'peek': false});
    expect(peek.enabled, isFalse);
    expect(saved.single.peek, isFalse);
    expect(bus.types, [windowStateMessage]);
    expect(bus.data(0)!['peek'], isFalse);
    expect(bus.data(0)!['expanded'], isTrue);
  });

  test('set expanded is a one-off that saves nothing', () {
    bus.send(windowSetMessage, {'expanded': true});
    expect(peek.expanded, isTrue);
    expect(saved, isEmpty);
    expect(bus.data(0)!['expanded'], isTrue);
    expect(remote.config.peek, isTrue);
  });

  test('every peek change is announced', () {
    peek.attention(true);
    expect(bus.types, [windowStateMessage]);
    expect(bus.data(0)!['expanded'], isTrue);
  });

  test('in window mode peek is saved but the window stays expanded', () {
    bus = RecordingBus();
    remote = make(const WindowConfig(mode: WindowMode.window));
    bus.send(windowSetMessage, {'peek': true});
    expect(saved.single.peek, isTrue);
    expect(peek.enabled, isFalse);
    expect(bus.data(0)!['peek'], isTrue);
    expect(bus.data(0)!['expanded'], isTrue);
  });

  test('a payload that is not an object or not bools is reported and ignored', () async {
    final faults = await collectFaults(() async {
      bus.handlers[windowSetMessage]!({'type': windowSetMessage, 'data': 'peek'});
      bus.send(windowSetMessage, {'peek': 'yes'});
      bus.send(windowSetMessage, {'expanded': 1});
    });
    expect(faults, hasLength(3));
    expect(saved, isEmpty);
    expect(bus.emitted, isEmpty);
    expect(peek.expanded, isFalse);
  });

  test('a save that fails is reported, and peek still changed', () async {
    bus = RecordingBus();
    final failing = make(float, persist: (_) async => throw StateError('disk full'));
    final faults = await collectFaults(() async {
      failing.setPeek(false);
      await Future<void>.delayed(Duration.zero);
    });
    expect(faults, hasLength(1));
    expect(failing.config.peek, isFalse);
    expect(peek.expanded, isTrue);
  });

  test('set visible hides and shows the window, announces and saves nothing', () {
    var notified = 0;
    remote.addListener(() => notified++);
    bus.send(windowSetMessage, {'visible': false});
    bus.send(windowSetMessage, {'visible': true});
    expect(applied, [false, true]);
    expect(saved, isEmpty);
    expect([bus.data(0)!['visible'], bus.data(1)!['visible']], [false, true]);
    expect(notified, 2);
  });

  test('set mode moves a widget, saves the mode and announces it', () {
    bus.send(windowSetMessage, {'mode': 'desktop'});
    expect(applied, [WindowMode.desktop]);
    expect(remote.config.mode, WindowMode.desktop);
    expect(saved.single.mode, WindowMode.desktop);
    expect(saved.single.peek, isTrue);
    expect(bus.data(0)!['mode'], 'desktop');
    bus.send(windowSetMessage, {'mode': 'float'});
    expect(applied, [WindowMode.desktop, WindowMode.float]);
    expect(bus.data(1)!['mode'], 'float');
  });

  test('switching to or from window mode, or to an unknown mode, is reported and ignored', () async {
    final faults = await collectFaults(() async {
      bus.send(windowSetMessage, {'mode': 'window'});
      bus.send(windowSetMessage, {'mode': 'sideways'});
      bus.send(windowSetMessage, {'mode': 3});
      bus = RecordingBus();
      make(const WindowConfig(mode: WindowMode.window)).setMode(WindowMode.float);
    });
    expect(faults, hasLength(4));
    expect(applied, isEmpty);
    expect(saved, isEmpty);
    expect(bus.emitted, isEmpty);
  });

  test('a native effect that fails is reported, and the state still changed', () async {
    bus = RecordingBus();
    final failing = make(
      float,
      effects: WindowEffects(
        mode: (_, {required from, required expanded}) async => throw StateError('no runner'),
        visible: (_) async => throw StateError('gone'),
      ),
    );
    final faults = await collectFaults(() async {
      failing.setMode(WindowMode.desktop);
      failing.setVisible(false);
      await Future<void>.delayed(Duration.zero);
    });
    expect(faults, hasLength(2));
    expect(failing.config.mode, WindowMode.desktop);
    expect(failing.visible, isFalse);
  });

  group('kiosk', () {
    test('a peeking widget enters kiosk: peek stops, the window expands, the mode is saved and announced once', () {
      bus.send(windowSetMessage, {'mode': 'kiosk'});
      expect(remote.config.mode, WindowMode.kiosk);
      expect(remote.config.kioskExit, WindowMode.float);
      expect(peek.enabled, isFalse);
      expect(moves, ['float -> kiosk, expanded true']);
      expect(saved.single.mode, WindowMode.kiosk);
      expect(saved.single.peek, isTrue);
      expect(bus.types, [windowStateMessage]);
      expect(bus.data(0)!['mode'], 'kiosk');
      expect(bus.data(0)!['expanded'], isTrue);
    });

    test('leaving goes back to the mode it came from, and peek collapses the widget again', () {
      remote.setMode(WindowMode.kiosk);
      remote.leaveKiosk();
      expect(remote.config.mode, WindowMode.float);
      expect(peek.enabled, isTrue);
      expect(moves.last, 'kiosk -> float, expanded false');
      expect(saved.last.mode, WindowMode.float);
      expect(bus.data(1)!['mode'], 'float');
    });

    test('toggle enters and leaves; leaving outside kiosk does nothing', () {
      remote.leaveKiosk();
      expect(moves, isEmpty);
      remote.toggleKiosk();
      remote.toggleKiosk();
      expect(applied, [WindowMode.kiosk, WindowMode.float]);
    });

    test('an ordinary window enters and leaves kiosk, though it still cannot become a widget', () async {
      bus = RecordingBus();
      final window = make(const WindowConfig(mode: WindowMode.window));
      window.toggleKiosk();
      window.toggleKiosk();
      expect(moves, ['window -> kiosk, expanded true', 'kiosk -> window, expanded true']);
      final faults = await collectFaults(() async => window.setMode(WindowMode.float));
      expect(faults, hasLength(1));
      expect(window.config.mode, WindowMode.window);
    });

    test('a kiosk started from the config leaves to the mode the file named', () {
      bus = RecordingBus();
      final kiosk = make(WindowConfig.from({'mode': 'desktop', 'peek': true}, const {'VISAGE_MODE': 'kiosk'}));
      expect(peek.enabled, isFalse);
      kiosk.leaveKiosk();
      expect(moves, ['kiosk -> desktop, expanded false']);
      expect(peek.enabled, isTrue);
    });

    test('peek set in kiosk is saved but does not collapse the window', () {
      remote.setMode(WindowMode.kiosk);
      remote.setPeek(false);
      remote.setPeek(true);
      expect(saved.last.peek, isTrue);
      expect(peek.enabled, isFalse);
      expect(peek.expanded, isTrue);
    });

    test('asking for the current mode announces it and saves nothing', () {
      bus.send(windowSetMessage, {'mode': 'float'});
      expect(saved, isEmpty);
      expect(moves, isEmpty);
      expect(bus.data(0)!['mode'], 'float');
    });
  });
}
