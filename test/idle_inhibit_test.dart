import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/idle_inhibit.dart';

import 'fake_inhibit_bus.dart';
import 'faults.dart';

void main() {
  test('kiosk holds one ScreenSaver inhibit and gives its cookie back', () async {
    final bus = FakeInhibitBus();
    final inhibitor = IdleInhibitor(bus);
    final faults = await collectFaults(() async {
      await inhibitor.hold();
      await inhibitor.hold();
      expect(inhibitor.held, isTrue);
      await inhibitor.release();
      await inhibitor.release();
    });
    expect(bus.calls, ['screenSaver.Inhibit(ovos-gui-visage)', 'screenSaver.UnInhibit(42)']);
    expect(inhibitor.held, isFalse);
    expect(faults, isEmpty);
  });

  test('a quick enter and leave runs in order, so no cookie is left behind', () async {
    final bus = FakeInhibitBus();
    final inhibitor = IdleInhibitor(bus);
    final hold = inhibitor.hold();
    final release = inhibitor.release();
    await Future.wait([hold, release]);
    expect(bus.calls, ['screenSaver.Inhibit(ovos-gui-visage)', 'screenSaver.UnInhibit(42)']);
  });

  // The fault reports are once per run, so the failure paths share one test.
  test('a missing ScreenSaver falls back to the portal, and every failure is reported once', () async {
    final bus = FakeInhibitBus(screenSaverFails: true);
    final inhibitor = IdleInhibitor(bus);
    final fallback = await collectFaults(() async {
      await inhibitor.hold();
      await inhibitor.release();
    });
    expect(bus.calls, [
      'screenSaver.Inhibit(ovos-gui-visage)',
      'portal.Inhibit',
      'portal.Close(/org/freedesktop/portal/desktop/request/1_1/t)',
    ]);
    expect([for (final f in fallback) '${f.context}'], [contains('org.freedesktop.ScreenSaver; trying the desktop portal')]);

    bus.portalFails = true;
    final neither = await collectFaults(() async {
      await inhibitor.hold();
      await inhibitor.hold();
    });
    expect(inhibitor.held, isFalse);
    expect([for (final f in neither) '${f.context}'], [contains('the display may blank in kiosk mode')]);

    final failedRelease = FakeInhibitBus()..unInhibitFails = true;
    final releasing = IdleInhibitor(failedRelease);
    final release = await collectFaults(() async {
      await releasing.hold();
      await releasing.release();
    });
    expect([for (final f in release) '${f.context}'], [contains('releasing the kiosk idle inhibit')]);
    expect(releasing.held, isFalse);
  });
}
