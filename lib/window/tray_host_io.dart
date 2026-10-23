import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../faults.dart';
import 'plugin_calls.dart';
import 'status_menu.dart';
import 'tray_watch_dbus_io.dart';

const trayIconAsset = 'assets/tray/ovos-gui-visage.png';
const trayToolTip = 'ovos-gui-visage';

/// The Linux tray item: an app indicator in the panel with the same menu as the macOS menu bar item. The panel opens
/// the menu itself on a click and reports the chosen item by key; checked entries become check items and entries
/// with children become submenus. macOS keeps its runner-drawn item, so the tray is created on Linux only, and a
/// desktop that cannot host one is reported once. Needs libayatana-appindicator3 at runtime (README). A session bus with
/// no tray watcher is reported once too (tray_watch.dart), since the plugin then succeeds and nothing shows.
class TrayHost with TrayListener {
  TrayHost({required this.onSelected});

  final void Function(String id) onSelected;
  bool _ready = false;
  bool _unavailable = false;
  TrayWatcherProbe? _probe;

  Future<void> show(List<MenuEntry> items) async {
    if (!Platform.isLinux || _unavailable) return;
    try {
      if (!_ready) await _create();
      await trayManager.setContextMenu(Menu(items: [for (final entry in items) _item(entry)]));
    } on Object catch (err, stack) {
      _unavailable = true;
      reportFault('the tray item', err, stack);
    }
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final id = menuItem.key;
    if (id != null) onSelected(id);
  }

  void dispose() {
    unawaited(_probe?.dispose());
    if (!_ready) return;
    trayManager.removeListener(this);
    trayManager.destroy();
  }

  /// The icon is required; the tooltip is not implemented by the Linux plugin and is reported once and skipped.
  Future<void> _create() async {
    unawaited((_probe = TrayWatcherProbe()).start());
    await trayManager.setIcon(trayIconAsset);
    await attemptPluginCall('the tray tooltip', () => trayManager.setToolTip(trayToolTip));
    trayManager.addListener(this);
    _ready = true;
  }
}

MenuItem _item(MenuEntry entry) {
  if (entry.separator) return MenuItem.separator();
  if (entry.children.isNotEmpty) {
    final submenu = Menu(items: [for (final child in entry.children) _item(child)]);
    return MenuItem.submenu(key: entry.id, label: entry.title, disabled: !entry.enabled, submenu: submenu);
  }
  if (_checkable(entry.id)) {
    return MenuItem.checkbox(key: entry.id, label: entry.title, checked: entry.checked, disabled: !entry.enabled);
  }
  return MenuItem(key: entry.id, label: entry.title, disabled: !entry.enabled);
}

/// Entries that show a check mark: peek, the modes, and the face and colour choices.
bool _checkable(String id) =>
    id == peekItem || id.startsWith('mode.') || id.startsWith(facePrefix) || id.startsWith(coloursPrefix);
