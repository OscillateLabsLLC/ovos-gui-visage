import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/face/styles.dart';
import 'package:ovos_gui_visage/window/status_menu.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

import 'faults.dart';

const _state = StatusMenuState(mode: WindowMode.float, peek: true, visible: true, face: FaceSpec.visage);

StatusMenuState _with({WindowMode? mode, bool? peek, bool? visible, FaceSpec? face}) => StatusMenuState(
  mode: mode ?? _state.mode,
  peek: peek ?? _state.peek,
  visible: visible ?? _state.visible,
  face: face ?? _state.face,
);

MenuEntry _item(List<MenuEntry> items, String id) => items.firstWhere((i) => i.id == id);

List<String> _checked(MenuEntry submenu) => [
  for (final c in submenu.children)
    if (c.checked) c.id,
];

void main() {
  test('the items top to bottom, for a floating peeking widget showing visage', () {
    final items = buildStatusMenu(_state);
    expect(
      [for (final i in items) i.separator ? '-' : i.title],
      [
        'Hide face',
        '-',
        'Peek mode',
        'Float above windows',
        'Sit on the desktop',
        '-',
        'Face',
        'Colours',
        '-',
        'Quit ovos-gui-visage',
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
    expect(items.first.title, 'Show face');
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

  test('the JSON the runner reads', () {
    final json = [for (final i in buildStatusMenu(_state)) i.toJson()];
    expect(json[0], {'id': 'visible', 'title': 'Hide face', 'checked': false, 'enabled': true});
    expect(json[1], {'separator': true});
    expect((json[6]['children']! as List).first, {'id': 'face.visage', 'title': 'Visage', 'checked': true, 'enabled': true});
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
          toggleVisible: () => calls.add('visible'),
          togglePeek: () => calls.add('peek'),
          setMode: (m) => calls.add('mode ${m.name}'),
          applyPreset: (n) => calls.add('preset $n'),
          applyColours: (n) => calls.add('colours $n'),
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
      for (final id in [visibleItem, peekItem, floatItem, desktopItem, 'face.mark1', 'colours.mint', quitItem]) {
        menu.dispatch(id);
      }
      expect(calls, ['visible', 'peek', 'mode float', 'mode desktop', 'preset mark1', 'colours mint', 'quit']);
    });

    test('an unknown id, preset or colourway is reported and does nothing', () async {
      final faults = await collectFaults(() async {
        for (final id in ['nope', 'face.nope', 'colours.nope', 'face', '']) {
          menu.dispatch(id);
        }
      });
      expect(faults, hasLength(5));
      expect(calls, isEmpty);
    });
  });
}
