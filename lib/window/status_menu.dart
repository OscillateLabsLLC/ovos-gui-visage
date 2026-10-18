/// The macOS menu bar item's menu, so the widget can be driven without the bus. Pure: [buildStatusMenu] turns the
/// current state into items, [StatusMenuController] rebuilds them on every change and dispatches a selected id. The
/// native half (status_menu_host.dart, macos/Runner/StatusMenu.swift) draws the items and sends ids back.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../face/face_palette.dart';
import '../face/face_spec.dart';
import '../face/styles.dart';
import '../faults.dart';
import 'window_config.dart';

const visibleItem = 'visible';
const peekItem = 'peek';
const floatItem = 'mode.float';
const desktopItem = 'mode.desktop';
const pickerItem = 'picker';
const quitItem = 'quit';
const facePrefix = 'face.';
const coloursPrefix = 'colours.';

class MenuEntry {
  const MenuEntry(this.id, this.title, {this.checked = false, this.enabled = true, this.children = const []}) : separator = false;

  const MenuEntry.separator() : id = '', title = '', checked = false, enabled = false, separator = true, children = const [];

  final String id;
  final String title;
  final bool checked;
  final bool enabled;
  final bool separator;
  final List<MenuEntry> children;

  Map<String, Object> toJson() => separator
      ? {'separator': true}
      : {
          'id': id,
          'title': title,
          'checked': checked,
          'enabled': enabled,
          if (children.isNotEmpty) 'children': [for (final child in children) child.toJson()],
        };
}

class StatusMenuState {
  const StatusMenuState({required this.mode, required this.peek, required this.visible, required this.face});

  final WindowMode mode;
  final bool peek;
  final bool visible;
  final FaceSpec face;
}

class StatusMenuActions {
  const StatusMenuActions({
    required this.toggleVisible,
    required this.togglePeek,
    required this.setMode,
    required this.applyPreset,
    required this.applyColours,
    required this.openPicker,
    required this.quit,
  });

  final VoidCallback toggleVisible;
  final VoidCallback togglePeek;
  final void Function(WindowMode mode) setMode;
  final void Function(String preset) applyPreset;
  final void Function(String colours) applyColours;
  final VoidCallback openPicker;
  final VoidCallback quit;
}

List<MenuEntry> buildStatusMenu(StatusMenuState state) {
  final widget = state.mode != WindowMode.window;
  return [
    MenuEntry(visibleItem, state.visible ? 'Hide face' : 'Show face'),
    const MenuEntry.separator(),
    MenuEntry(peekItem, 'Peek mode', checked: state.peek, enabled: widget),
    MenuEntry(floatItem, 'Float above windows', checked: state.mode == WindowMode.float, enabled: widget),
    MenuEntry(desktopItem, 'Sit on the desktop', checked: state.mode == WindowMode.desktop, enabled: widget),
    const MenuEntry.separator(),
    MenuEntry('face', 'Face', children: _choices(facePresets.keys, facePrefix, state.face.presetName)),
    MenuEntry('colours', 'Colours', children: _choices(facePalettes.keys, coloursPrefix, state.face.colours.name)),
    const MenuEntry(pickerItem, 'Face picker…'),
    const MenuEntry.separator(),
    const MenuEntry(quitItem, 'Quit ovos-gui-visage'),
  ];
}

List<MenuEntry> _choices(Iterable<String> names, String prefix, String? current) => [
  for (final name in names) MenuEntry('$prefix$name', menuTitle(name), checked: name == current),
];

/// "mark1" reads "Mark 1": the first letter upper-cased, a space before trailing digits.
String menuTitle(String name) => name
    .replaceFirstMapped(RegExp(r'^(\D*?)(\d+)$'), (m) => '${m[1]} ${m[2]}')
    .replaceFirstMapped(RegExp('^.'), (m) => m[0]!.toUpperCase());

/// Shows the menu built from [read] now and after every [changes] notification, sending it to [show] only when it
/// differs from the last one sent; [dispatch] routes a selected id to [actions].
class StatusMenuController {
  StatusMenuController({required this.changes, required this.read, required this.show, required this.actions}) {
    changes.addListener(refresh);
    refresh();
  }

  final Listenable changes;
  final StatusMenuState Function() read;
  final void Function(List<MenuEntry> items) show;
  final StatusMenuActions actions;
  String? _shown;

  void refresh() {
    final items = buildStatusMenu(read());
    final json = jsonEncode([for (final item in items) item.toJson()]);
    if (json == _shown) return;
    _shown = json;
    show(items);
  }

  void dispatch(String id) {
    final preset = _suffix(id, facePrefix, facePresets.keys);
    final colours = _suffix(id, coloursPrefix, facePalettes.keys);
    if (preset != null) return actions.applyPreset(preset);
    if (colours != null) return actions.applyColours(colours);
    switch (id) {
      case visibleItem:
        actions.toggleVisible();
      case peekItem:
        actions.togglePeek();
      case floatItem:
        actions.setMode(WindowMode.float);
      case desktopItem:
        actions.setMode(WindowMode.desktop);
      case pickerItem:
        actions.openPicker();
      case quitItem:
        actions.quit();
      default:
        reportFault('menu item "$id"', ArgumentError.value(id, 'id', 'not an item of the status menu'));
    }
  }

  void dispose() => changes.removeListener(refresh);
}

String? _suffix(String id, String prefix, Iterable<String> names) {
  final name = id.startsWith(prefix) ? id.substring(prefix.length) : null;
  return names.contains(name) ? name : null;
}
