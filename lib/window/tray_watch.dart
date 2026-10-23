/// The bus name a tray host (Plasma's panel, GNOME's AppIndicator extension) registers items through.
const trayWatcherName = 'org.kde.StatusNotifierWatcher';

/// Why the tray item does not show, named for the desktop where it is most often missing.
const trayWatcherFault =
    'the tray item: no StatusNotifierWatcher on the session bus, so no panel can show it. On GNOME, install and enable '
    'the "AppIndicator and KStatusNotifierItem Support" extension (gnome-shell-extension-appindicator). The item '
    'appears without a restart once a watcher starts; until then the menu is reachable over the bus '
    '(visage.window.*, visage.face.*)';

/// What the tray host does when the watcher is seen to be present or absent.
enum TrayWatchStep { none, reportMissing, appeared }

/// The tray watcher's presence over a run. An absent watcher is a reliable "no tray" (issue #14); a present one is
/// necessary but not proof of a visible tray, since KDE's watcher answers with no panel running. The missing tray is
/// reported once per run; a watcher that starts later is logged, and libayatana registers the item with it by itself.
class TrayWatch {
  bool? _present;
  bool _reported = false;

  bool? get present => _present;

  TrayWatchStep observe({required bool present}) {
    final was = _present;
    _present = present;
    if (!present) {
      if (_reported) return TrayWatchStep.none;
      _reported = true;
      return TrayWatchStep.reportMissing;
    }
    return was == false ? TrayWatchStep.appeared : TrayWatchStep.none;
  }
}
