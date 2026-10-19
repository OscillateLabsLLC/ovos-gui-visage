import 'dart:io';

import 'package:tray_manager/tray_manager.dart';

import '../faults.dart';
import 'status_menu.dart';

const trayIconAsset = 'assets/tray/ovos-gui-visage.png';
const trayToolTip = 'ovos-gui-visage';

/// The Linux tray item: a StatusNotifierItem in the panel with the same menu as the macOS menu bar item. The panel
/// opens the menu itself and reports the chosen item; checked entries become check items and entries with children
/// become submenus. macOS keeps its runner-drawn item, so the tray is created on Linux only, and a desktop that
/// cannot host one is reported once.
class TrayHost {
  TrayHost({required this.onSelected});

  final void Function(String id) onSelected;
  TrayIcon? _icon;
  Menu? _menu;
  bool _unavailable = false;

  Future<void> show(List<MenuEntry> items) async {
    if (!Platform.isLinux || _unavailable) return;
    try {
      final icon = _icon ??= _createIcon();
      final menu = _buildMenu(items);
      icon.setContextMenu(menu);
      _menu?.dispose();
      _menu = menu;
    } on Object catch (err, stack) {
      _unavailable = true;
      reportFault('the tray item', err, stack);
    }
  }

  void dispose() {
    _menu?.dispose();
    _icon?.dispose();
  }

  TrayIcon _createIcon() {
    final icon = TrayIcon.create();
    if (icon == null) throw StateError('this desktop offers no tray item');
    icon.icon = ImageAsset.fromAsset(trayIconAsset);
    icon.setTooltip(trayToolTip);
    icon.setVisible(true);
    return icon;
  }

  Menu _buildMenu(List<MenuEntry> entries) {
    final menu = Menu.create();
    if (menu == null) throw StateError('no tray menu could be created');
    for (final entry in entries) {
      if (entry.separator) {
        menu.addSeparator();
      } else {
        menu.addItem(_item(entry));
      }
    }
    return menu;
  }

  MenuItem _item(MenuEntry entry) {
    final type = entry.children.isNotEmpty
        ? MenuItemType.submenu
        : _checkable(entry.id)
        ? MenuItemType.checkbox
        : MenuItemType.normal;
    final item = MenuItem.createWithLabelAndType(entry.title, type);
    if (item == null) throw StateError('no tray menu item could be created for "${entry.id}"');
    item.isEnabled = entry.enabled;
    if (type == MenuItemType.checkbox) item.state = entry.checked ? MenuItemState.checked : MenuItemState.unchecked;
    if (type == MenuItemType.submenu) item.submenu = _buildMenu(entry.children);
    if (type != MenuItemType.submenu) {
      item.addListener((event) {
        if (event is MenuItemClickedEvent) onSelected(entry.id);
      });
    }
    return item;
  }
}

/// Entries that show a check mark: peek, the modes, and the face and colour choices.
bool _checkable(String id) =>
    id == peekItem || id.startsWith('mode.') || id.startsWith(facePrefix) || id.startsWith(coloursPrefix);
