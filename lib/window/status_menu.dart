/// The app's menu, so the widget can be driven without the bus. Pure: [buildStatusMenu] turns the current state into
/// items, [StatusMenuController] rebuilds them on every change and dispatches a selected id. Three hosts draw the same
/// items and send ids back: the macOS menu bar item (status_menu_host.dart, macos/Runner/StatusMenu.swift), the Linux
/// tray (tray_host_io.dart) and the in-window menu (window_menu.dart) on every platform.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../face/face_palette.dart';
import '../face/face_spec.dart';
import '../face/styles.dart';
import '../faults.dart';
import '../volume_controls.dart';
import 'window_config.dart';

const typeItem = 'type';
const visibleItem = 'visible';
const peekItem = 'peek';
const floatItem = 'mode.float';
const desktopItem = 'mode.desktop';
const kioskItem = 'mode.kiosk';
const pickerItem = 'picker';
const volumeItem = 'volume';
const volumeUpItem = 'volume.up';
const volumeDownItem = 'volume.down';
const muteItem = 'volume.mute';
const quitItem = 'quit';
const protocolItem = 'protocol';
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
  const StatusMenuState({
    required this.mode,
    required this.peek,
    required this.visible,
    required this.face,
    this.volume,
    this.muted = false,
    this.protocol,
  });

  final WindowMode mode;
  final bool peek;
  final bool visible;
  final FaceSpec face;

  /// 0 to 1, null until a volume plugin has reported.
  final double? volume;
  final bool muted;

  /// The GUI protocol line (protocol/wire_protocol.dart `protocolTitle`), shown greyed out; null shows none.
  final String? protocol;
}

class StatusMenuActions {
  const StatusMenuActions({
    required this.typeCommand,
    required this.toggleVisible,
    required this.togglePeek,
    required this.setMode,
    required this.toggleKiosk,
    required this.applyPreset,
    required this.applyColours,
    required this.openPicker,
    required this.volume,
    required this.quit,
  });

  final VoidCallback typeCommand;
  final VoidCallback toggleVisible;
  final VoidCallback togglePeek;
  final void Function(WindowMode mode) setMode;
  final VoidCallback toggleKiosk;
  final void Function(String preset) applyPreset;
  final void Function(String colours) applyColours;
  final VoidCallback openPicker;
  final void Function(VolumeAction action) volume;
  final VoidCallback quit;
}

List<MenuEntry> buildStatusMenu(StatusMenuState state) {
  final widget = state.mode == WindowMode.float || state.mode == WindowMode.desktop;
  final levels = state.mode != WindowMode.window;
  return [
    const MenuEntry(typeItem, 'Type a command…'),
    MenuEntry(visibleItem, state.visible ? 'Hide face' : 'Show face'),
    _volume(state),
    const MenuEntry.separator(),
    MenuEntry(peekItem, 'Peek mode', checked: state.peek, enabled: widget),
    MenuEntry(floatItem, 'Float above windows', checked: state.mode == WindowMode.float, enabled: levels),
    MenuEntry(desktopItem, 'Sit on the desktop', checked: state.mode == WindowMode.desktop, enabled: levels),
    MenuEntry(kioskItem, 'Full screen', checked: state.mode == WindowMode.kiosk),
    const MenuEntry.separator(),
    MenuEntry('face', 'Face', children: _choices(facePresets.keys, facePrefix, state.face.presetName)),
    MenuEntry('colours', 'Colours', children: _choices(facePalettes.keys, coloursPrefix, state.face.colours.name)),
    const MenuEntry(pickerItem, 'Face picker…'),
    const MenuEntry.separator(),
    if (state.protocol case final protocol?) MenuEntry(protocolItem, protocol, enabled: false),
    const MenuEntry(quitItem, 'Quit OVOS Visage'),
  ];
}

MenuEntry _volume(StatusMenuState state) => MenuEntry(
  volumeItem,
  volumeTitle(state.volume, muted: state.muted),
  children: [
    const MenuEntry(volumeUpItem, 'Volume up'),
    const MenuEntry(volumeDownItem, 'Volume down'),
    MenuEntry(muteItem, 'Mute', checked: state.muted),
  ],
);

String volumeTitle(double? volume, {required bool muted}) {
  if (muted) return 'Volume (muted)';
  return volume == null ? 'Volume' : 'Volume (${(volume * 100).round()}%)';
}

List<MenuEntry> _choices(Iterable<String> names, String prefix, String? current) => [
  for (final name in names) MenuEntry('$prefix$name', menuTitle(name), checked: name == current),
];

/// Entries that show a check mark: peek, mute, the modes, and the face and colour choices.
bool isCheckable(MenuEntry entry) =>
    entry.id == peekItem ||
    entry.id == muteItem ||
    entry.id.startsWith('mode.') ||
    entry.id.startsWith(facePrefix) ||
    entry.id.startsWith(coloursPrefix);

/// The menu as the window itself shows it: hiding the window from inside it would strand a desktop with no menu bar
/// item or tray, and a browser tab cannot quit, so those entries (and a separator they leave dangling) go.
List<MenuEntry> windowMenuEntries(List<MenuEntry> items, {required bool canQuit}) {
  final kept = [
    for (final item in items)
      if (item.id != visibleItem && (canQuit || item.id != quitItem)) item,
  ];
  return [
    for (final (index, item) in kept.indexed)
      if (!item.separator || (index > 0 && index < kept.length - 1 && !kept[index + 1].separator)) item,
  ];
}

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
    final action = _plainActions[id];
    if (action == null) {
      return reportFault('menu item "$id"', ArgumentError.value(id, 'id', 'not an item of the status menu'));
    }
    action();
  }

  late final Map<String, VoidCallback> _plainActions = {
    typeItem: actions.typeCommand,
    visibleItem: actions.toggleVisible,
    peekItem: actions.togglePeek,
    floatItem: () => actions.setMode(WindowMode.float),
    desktopItem: () => actions.setMode(WindowMode.desktop),
    kioskItem: actions.toggleKiosk,
    pickerItem: actions.openPicker,
    volumeUpItem: () => actions.volume(VolumeAction.up),
    volumeDownItem: () => actions.volume(VolumeAction.down),
    muteItem: () => actions.volume(VolumeAction.toggleMute),
    quitItem: actions.quit,
  };

  void dispose() => changes.removeListener(refresh);
}

String? _suffix(String id, String prefix, Iterable<String> names) {
  final name = id.startsWith(prefix) ? id.substring(prefix.length) : null;
  return names.contains(name) ? name : null;
}
