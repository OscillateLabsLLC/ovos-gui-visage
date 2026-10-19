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
  late List<WindowConfig> saved;
  late List<String> placed;
  late WindowRemote remote;

  WindowRemote make(WindowConfig config) {
    final peek = PeekController(enabled: config.peeks, timer: ManualTimers().create);
    final effects = WindowEffects(
      mode: (c, {required from, required expanded}) async {},
      visible: (v) async {},
      place: (c, {required expanded}) async => placed.add('${c.corner.name}, expanded $expanded'),
    );
    return WindowRemote(bus, peek, initial: config, persist: (c) async => saved.add(c), effects: effects);
  }

  setUp(() {
    bus = RecordingBus();
    saved = [];
    placed = [];
    remote = make(float);
  });

  test('a new corner is placed, saved and announced', () async {
    remote.setCorner(Corner.topLeft);
    await Future<void>.delayed(Duration.zero);
    expect(remote.config.corner, Corner.topLeft);
    expect(saved.single.corner, Corner.topLeft);
    expect(placed, ['topLeft, expanded false']);
    expect(bus.types, [windowStateMessage]);
    expect(bus.data(0)!['corner'], 'topLeft');
  });

  test('the same corner only puts the widget back, as after a short drag', () async {
    remote.setCorner(Corner.bottomRight);
    await Future<void>.delayed(Duration.zero);
    expect(saved, isEmpty);
    expect(placed, ['bottomRight, expanded false']);
    expect(bus.types, isEmpty);
  });

  test('the bus sets a corner by name and reports a bad one', () async {
    bus.send(windowSetMessage, {'corner': 'topRight'});
    await Future<void>.delayed(Duration.zero);
    expect(remote.config.corner, Corner.topRight);
    final faults = await collectFaults(() async => bus.send(windowSetMessage, {'corner': 'middle'}));
    expect(faults, hasLength(1));
    expect(remote.config.corner, Corner.topRight);
  });

  test('an ordinary window has no corner to move to', () async {
    remote = make(const WindowConfig(mode: WindowMode.window));
    remote.setCorner(Corner.topLeft);
    await Future<void>.delayed(Duration.zero);
    expect(saved, isEmpty);
    expect(placed, isEmpty);
    expect(bus.types, [windowStateMessage]);
  });
}
