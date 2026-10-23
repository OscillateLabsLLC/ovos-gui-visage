import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/tray_watch.dart';

List<TrayWatchStep> _run(List<bool> presence) {
  final watch = TrayWatch();
  return [for (final present in presence) watch.observe(present: present)];
}

void main() {
  test('a watcher present from the start reports nothing', () {
    expect(_run([true]), [TrayWatchStep.none]);
  });

  test('no watcher at the start is reported once, and its arrival is logged', () {
    expect(_run([false, true]), [TrayWatchStep.reportMissing, TrayWatchStep.appeared]);
  });

  test('the missing tray is reported once per run, however often the watcher comes and goes', () {
    expect(_run([false, false, true, false, true]), [
      TrayWatchStep.reportMissing,
      TrayWatchStep.none,
      TrayWatchStep.appeared,
      TrayWatchStep.none,
      TrayWatchStep.appeared,
    ]);
  });

  test('a watcher that leaves after the start is reported then', () {
    expect(_run([true, false, true]), [TrayWatchStep.none, TrayWatchStep.reportMissing, TrayWatchStep.appeared]);
  });

  test('the message names the GNOME extension and the bus fallback', () {
    expect(trayWatcherFault, contains('AppIndicator and KStatusNotifierItem Support'));
    expect(trayWatcherFault, contains('visage.window.*'));
    final watch = TrayWatch();
    expect(watch.present, isNull);
    watch.observe(present: false);
    expect(watch.present, isFalse);
  });
}
