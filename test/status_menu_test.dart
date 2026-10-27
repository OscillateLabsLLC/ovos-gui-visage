import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/face/styles.dart';
import 'package:ovos_gui_visage/window/status_menu.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

import 'faults.dart';

const _state = StatusMenuState(mode: WindowMode.float, peek: true, visible: true, face: FaceSpec.visage);

StatusMenuState _with({WindowMode? mode, bool? peek, bool? visible, FaceSpec? face, double? volume, bool muted = false}) =>
    StatusMenuState(
      mode: mode ?? _state.mode,
      peek: peek ?? _state.peek,
      visible: visible ?? _state.visible,
      face: face ?? _state.face,
      volume: volume,
      muted: muted,
    );

MenuEntry _item(List<MenuEntry> items, String id) => items.firstWhere((i) => i.id == id);

List<String> _checked(MenuEntry submenu) => [
  for (final c in submenu.children)
    if (c.checked) c.id,
];

void main() {
  test('the protocol line sits greyed out above Quit, in every menu, and only when given', () {
    const state = StatusMenuState(
      mode: WindowMode.float,
      peek: true,
      visible: true,
      face: FaceSpec.visage,
      protocol: 'Protocol: GUI-1',
    );
    final items = buildStatusMenu(state);
    final protocol = _item(items, protocolItem);
    expect([protocol.title, protocol.enabled, isCheckable(protocol)], ['Protocol: GUI-1', false, false]);
    expect(items.indexOf(protocol), items.length - 2);
    expect(_item(windowMenuEntries(items, canQuit: false), protocolItem).title, 'Protocol: GUI-1');
    expect(buildStatusMenu(_state).where((i) => i.id == protocolItem), isEmpty);
  });

  test('the items top to bottom, for a floating peeking widget showing visage', () {
    final items = buildStatusMenu(_state);
    expect(
      [for (final i in items) i.separator ? '-' : i.title],
      [
        'Type a command…',
        'Hide face',
        'Volume',
        '-',
        'Peek mode',
        'Float above windows',
        'Sit on the desktop',
        'Full screen',
        '-',
        'Face',
        'Colours',
        'Face picker…',
        '-',
        'Quit OVOS Visage',
      ],
    );
    expect(
      [
        for (final i in items)
          if (i.checked) i.id,
      ],
      [peekItem, floatItem],
    );
    expect(_checked(_item(items, 'face')), ['face.visage']);
    expect(_checked(_item(items, 'colours')), ['colours.visage']);
  });

  test('the submenus list every preset and colourway in order, title-cased', () {
    final items = buildStatusMenu(_state);
    expect([for (final c in _item(items, 'face').children) c.id], [for (final n in facePresets.keys) 'face.$n']);
    expect([for (final c in _item(items, 'colours').children) c.id], [for (final n in facePalettes.keys) 'colours.$n']);
    expect(_item(items, 'face').children[1].title, 'Mark 1');
    expect(_item(items, 'colours').children[1].title, 'Ember');
  });

  test('a hidden face, peek off, on the desktop', () {
    final items = buildStatusMenu(_with(visible: false, peek: false, mode: WindowMode.desktop));
    expect(_item(items, visibleItem).title, 'Show face');
    expect(
      [
        for (final i in items)
          if (i.checked) i.id,
      ],
      [desktopItem],
    );
  });

  test('an ordinary window greys out peek and the widget levels', () {
    final items = buildStatusMenu(_with(mode: WindowMode.window));
    expect(
      [
        for (final i in items)
          if (!i.enabled && !i.separator) i.id,
      ],
      [peekItem, floatItem, desktopItem],
    );
    expect(_item(items, floatItem).checked, isFalse);
    expect(_item(items, kioskItem).enabled, isTrue);
  });

  test('kiosk checks Full screen, greys out peek and keeps the widget levels as ways out', () {
    final items = buildStatusMenu(_with(mode: WindowMode.kiosk));
    expect(
      [
        for (final i in items)
          if (i.checked) i.id,
      ],
      [peekItem, kioskItem],
    );
    expect(
      [
        for (final i in items)
          if (!i.enabled && !i.separator) i.id,
      ],
      [peekItem],
    );
  });

  test('a custom pairing checks no preset; custom colours check no colourway; a preset in other colours keeps both', () {
    const custom = FaceSpec(eyes: 'block', mouth: 'orb', colours: FacePalette.ember);
    var items = buildStatusMenu(_with(face: custom));
    expect(_checked(_item(items, 'face')), isEmpty);
    expect(_checked(_item(items, 'colours')), ['colours.ember']);
    items = buildStatusMenu(
      _with(
        face: FaceSpec.parse({
          'preset': 'retro',
          'colours': {'eye': '#123456'},
        }),
      ),
    );
    expect(_checked(_item(items, 'face')), ['face.retro']);
    expect(_checked(_item(items, 'colours')), isEmpty);
  });

  test('the volume submenu: up, down and a mute check; its title carries the level once a plugin has reported', () {
    var volume = _item(buildStatusMenu(_state), volumeItem);
    expect([for (final c in volume.children) c.title], ['Volume up', 'Volume down', 'Mute']);
    expect([for (final c in volume.children) c.id], [volumeUpItem, volumeDownItem, muteItem]);
    expect([volume.title, _checked(volume)], ['Volume', isEmpty]);
    expect([for (final c in volume.children) isCheckable(c)], [false, false, true]);
    volume = _item(buildStatusMenu(_with(volume: 0.38)), volumeItem);
    expect(volume.title, 'Volume (38%)');
    volume = _item(buildStatusMenu(_with(volume: 0.38, muted: true)), volumeItem);
    expect(
      [volume.title, _checked(volume)],
      [
        'Volume (muted)',
        [muteItem],
      ],
    );
  });

  test('the in-window menu keeps the volume submenu', () {
    final items = windowMenuEntries(buildStatusMenu(_state), canQuit: true);
    expect(_item(items, volumeItem).children, hasLength(3));
  });

  test('the JSON the runner reads', () {
    final json = [for (final i in buildStatusMenu(_state)) i.toJson()];
    expect(json[0], {'id': 'type', 'title': 'Type a command…', 'checked': false, 'enabled': true});
    expect(json[1], {'id': 'visible', 'title': 'Hide face', 'checked': false, 'enabled': true});
    expect(json[3], {'separator': true});
    expect((json[9]['children']! as List).first, {'id': 'face.visage', 'title': 'Visage', 'checked': true, 'enabled': true});
  });

  group('controller', () {
    late ChangeNotifier changes;
    late StatusMenuState state;
    late List<List<MenuEntry>> shown;
    late List<String> calls;
    late StatusMenuController menu;

    setUp(() {
      changes = ChangeNotifier();
      state = _state;
      shown = [];
      calls = [];
      menu = StatusMenuController(
        changes: changes,
        read: () => state,
        show: shown.add,
        actions: StatusMenuActions(
          typeCommand: () => calls.add('type'),
          toggleVisible: () => calls.add('visible'),
          togglePeek: () => calls.add('peek'),
          setMode: (m) => calls.add('mode ${m.name}'),
          toggleKiosk: () => calls.add('kiosk'),
          applyPreset: (n) => calls.add('preset $n'),
          applyColours: (n) => calls.add('colours $n'),
          openPicker: () => calls.add('picker'),
          volume: (a) => calls.add('volume ${a.name}'),
          quit: () => calls.add('quit'),
        ),
      );
    });

    test('shows at once, and again only when a change alters the items', () {
      expect(shown, hasLength(1));
      changes.notifyListeners();
      expect(shown, hasLength(1));
      state = _with(peek: false);
      changes.notifyListeners();
      expect(shown, hasLength(2));
      expect(_item(shown.last, peekItem).checked, isFalse);
      menu.dispose();
      state = _with(visible: false);
      changes.notifyListeners();
      expect(shown, hasLength(2));
    });

    test('dispatches every id', () {
      for (final id in [
        typeItem,
        visibleItem,
        peekItem,
        floatItem,
        desktopItem,
        kioskItem,
        'face.mark1',
        'colours.mint',
        pickerItem,
        volumeUpItem,
        volumeDownItem,
        muteItem,
        quitItem,
      ]) {
        menu.dispatch(id);
      }
      expect(calls, [
        'type',
        'visible',
        'peek',
        'mode float',
        'mode desktop',
        'kiosk',
        'preset mark1',
        'colours mint',
        'picker',
        'volume up',
        'volume down',
        'volume toggleMute',
        'quit',
      ]);
    });

    test('an unknown id, preset or colourway is reported and does nothing', () async {
      final faults = await collectFaults(() async {
        for (final id in ['nope', 'face.nope', 'colours.nope', 'face', '', volumeItem]) {
          menu.dispatch(id);
        }
      });
      expect(faults, hasLength(6));
      expect(calls, isEmpty);
    });
  });
}
