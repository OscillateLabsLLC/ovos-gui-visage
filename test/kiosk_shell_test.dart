import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/idle_inhibit.dart';
import 'package:ovos_gui_visage/window/kiosk_shell_io.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

import 'fake_inhibit_bus.dart';
import 'faults.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a runner without the kiosk calls reports each missing call once and carries on', () async {
    final bus = FakeInhibitBus();
    kioskIdleInhibitor = IdleInhibitor(bus);
    Future<void> roundTrip() async {
      await enterKiosk(from: WindowMode.float);
      await leaveKiosk(const WindowConfig(mode: WindowMode.float), bounds: () async => const Rect.fromLTWH(0, 0, 96, 96));
    }

    final first = await collectFaults(roundTrip);
    final again = await collectFaults(roundTrip);
    final contexts = [for (final fault in first) '${fault.context}'];
    expect(contexts, contains('setKiosk is not implemented by this platform runner'));
    // macOS keeps the display awake in its runner; Linux takes a session-bus idle inhibit and gives it back.
    if (Platform.isMacOS) expect(contexts, contains('setKeepAwake is not implemented by this platform runner'));
    if (Platform.isLinux) expect(bus.calls, hasLength(4));
    // macOS sizes the window to the display; elsewhere the window manager's fullscreen state does it.
    expect(contexts, contains(Platform.isMacOS ? 'getPrimaryDisplay in kiosk mode' : 'setFullScreen in kiosk mode'));
    expect(contexts, contains('setBounds in kiosk mode'));
    expect(contexts.toSet(), hasLength(contexts.length));
    expect(again, isEmpty);
  });
}
