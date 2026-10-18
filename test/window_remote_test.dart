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
  late WindowRemote remote;

  WindowRemote make(WindowConfig config, {WindowPersist? persist, WindowEffects? effects}) {
    peek = PeekController(enabled: config.peeks, timer: ManualTimers().create);
    final recording = WindowEffects(mode: (m) async => applied.add(m), visible: (v) async => applied.add(v));
    return WindowRemote(bus, peek, initial: config, persist: persist ?? (c) async => saved.add(c), effects: effects ?? recording);
  }

  setUp(() {
    bus = RecordingBus();
    saved = [];
    applied = [];
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
      effects: WindowEffects(mode: (_) async => throw StateError('no runner'), visible: (_) async => throw StateError('gone')),
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
}
