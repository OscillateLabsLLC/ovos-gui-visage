import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

void main() {
  _nearestCornerTests();
  test('defaults to a desktop widget in the top-right corner', () {
    final config = WindowConfig.from(null, const {});
    expect(config.mode, WindowMode.desktop);
    expect(config.isWidget, isTrue);
    expect(config.corner, Corner.topRight);
    expect(config.height, defaultWidgetHeight);
  });

  test('the file sets the mode and the environment overrides it', () {
    final file = {'mode': 'desktop', 'corner': 'bottom-left', 'height': 300, 'margin': 8};
    final fromFile = WindowConfig.from(file, const {});
    expect(fromFile.mode, WindowMode.desktop);
    expect(fromFile.corner, Corner.bottomLeft);
    expect(fromFile.size, const Size(180, 300));
    expect(fromFile.margin, 8);
    final overridden = WindowConfig.from(file, const {
      'VISAGE_MODE': 'float',
      'VISAGE_CORNER': 'TOP_RIGHT',
      'VISAGE_HEIGHT': '500',
    });
    expect(overridden.mode, WindowMode.float);
    expect(WindowConfig.from(file, const {'VISAGE_MODE': 'window'}).isWidget, isFalse);
    expect(overridden.corner, Corner.topRight);
    expect(overridden.height, 500);
  });

  test('bad values fall back instead of failing', () {
    final config = WindowConfig.from({'mode': 'sideways', 'height': -5, 'margin': 'x'}, const {'VISAGE_CORNER': 'middle'});
    expect(config.mode, WindowMode.desktop);
    expect(config.corner, Corner.topRight);
    expect(config.height, defaultWidgetHeight);
    expect(config.margin, defaultMargin);
  });

  test('the window sits in the chosen corner of the work area with its margin', () {
    const area = Rect.fromLTWH(0, 25, 1440, 875);
    Offset at(Corner corner) => WindowConfig(mode: WindowMode.desktop, corner: corner, height: 400, margin: 16).placeIn(area);
    expect(at(Corner.topLeft), const Offset(16, 41));
    expect(at(Corner.topRight), const Offset(1440 - 240 - 16, 41));
    expect(at(Corner.bottomLeft), const Offset(16, 900 - 400 - 16));
    expect(at(Corner.bottomRight), const Offset(1440 - 240 - 16, 900 - 400 - 16));
  });

  test('peek is off by default, set by the file, overridden by the environment', () {
    final defaults = WindowConfig.from(null, const {});
    expect(defaults.peek, isFalse);
    expect(defaults.peekSize, defaultPeekSize);
    final file = {'mode': 'float', 'peek': true, 'peekSize': 120};
    expect(WindowConfig.from(file, const {}).peek, isTrue);
    expect(WindowConfig.from(file, const {}).peekWindowSize, const Size(120, 120));
    expect(WindowConfig.from(file, const {'VISAGE_PEEK': 'off'}).peek, isFalse);
    expect(WindowConfig.from(null, const {'VISAGE_PEEK': 'Yes', 'VISAGE_PEEK_SIZE': '64'}).peekSize, 64);
    for (final on in ['1', 'true', 'yes', 'on']) {
      expect(WindowConfig.from(null, {'VISAGE_PEEK': on}).peek, isTrue, reason: on);
    }
    for (final off in ['0', 'false', 'no', 'off']) {
      expect(WindowConfig.from(file, {'VISAGE_PEEK': off}).peek, isFalse, reason: off);
    }
  });

  test('bad peek values fall back to the defaults', () {
    final config = WindowConfig.from({'peek': 'maybe', 'peekSize': 0}, const {});
    expect(config.peek, isFalse);
    expect(config.peekSize, defaultPeekSize);
  });

  test('peek applies to the widget modes only', () {
    expect(const WindowConfig(mode: WindowMode.float, peek: true).peeks, isTrue);
    expect(const WindowConfig(mode: WindowMode.desktop, peek: true).peeks, isTrue);
    expect(const WindowConfig(mode: WindowMode.window, peek: true).peeks, isFalse);
    expect(const WindowConfig(mode: WindowMode.float).peeks, isFalse);
  });

  test('collapsed and expanded bounds share the corner and its margin', () {
    const area = Rect.fromLTWH(0, 25, 1440, 875);
    Rect bounds(Corner corner, {required bool expanded}) =>
        WindowConfig(corner: corner, peek: true).boundsIn(area, expanded: expanded);
    expect(bounds(Corner.bottomRight, expanded: false), const Rect.fromLTWH(1440 - 96 - 16, 900 - 96 - 16, 96, 96));
    expect(bounds(Corner.bottomRight, expanded: true), const Rect.fromLTWH(1440 - 240 - 16, 900 - 400 - 16, 240, 400));
    expect(bounds(Corner.topLeft, expanded: false), const Rect.fromLTWH(16, 41, 96, 96));
    expect(bounds(Corner.topRight, expanded: false).topRight, const Offset(1440 - 16, 41));
    expect(bounds(Corner.bottomLeft, expanded: true).bottomLeft, const Offset(16, 900 - 16));
  });

  test('kiosk comes from the file or the environment, is not a widget and never peeks', () {
    final kiosk = WindowConfig.from({'mode': 'kiosk', 'peek': true}, const {});
    expect(kiosk.mode, WindowMode.kiosk);
    expect(kiosk.isKiosk, isTrue);
    expect(kiosk.isWidget, isFalse);
    expect(kiosk.peeks, isFalse);
    expect(WindowConfig.from(null, const {'VISAGE_MODE': 'KIOSK'}).isKiosk, isTrue);
  });

  test('the environment still wins over a file that says kiosk', () {
    final config = WindowConfig.from(
      {'mode': 'kiosk', 'peek': true},
      const {'VISAGE_MODE': 'float', 'VISAGE_CORNER': 'bottom-right'},
    );
    expect(config.mode, WindowMode.float);
    expect(config.corner, Corner.bottomRight);
    expect(config.peeks, isTrue);
  });

  test('leaving kiosk goes to the file mode, float when the file says kiosk, desktop when it says nothing', () {
    WindowMode exit(Map<String, dynamic>? file) => WindowConfig.from(file, const {'VISAGE_MODE': 'kiosk'}).kioskExit;
    expect(exit({'mode': 'window'}), WindowMode.window);
    expect(exit({'mode': 'float'}), WindowMode.float);
    expect(exit({'mode': 'kiosk'}), WindowMode.float);
    expect(exit({'mode': 'sideways'}), WindowMode.desktop);
    expect(exit(null), WindowMode.desktop);
  });

  test('copyWith changes peek and keeps the rest', () {
    const config = WindowConfig(mode: WindowMode.float, corner: Corner.bottomLeft, height: 300, margin: 8, peekSize: 80);
    final changed = config.copyWith(peek: true);
    expect(changed.peek, isTrue);
    expect(
      [changed.mode, changed.corner, changed.height, changed.margin, changed.peekSize],
      [WindowMode.float, Corner.bottomLeft, 300, 8, 80],
    );
  });
}

void _nearestCornerTests() {
  const area = Rect.fromLTWH(0, 0, 1920, 1080);
  test('a dropped widget belongs to the corner its centre is nearest to', () {
    expect(nearestCorner(const Rect.fromLTWH(10, 10, 240, 400), area), Corner.topLeft);
    expect(nearestCorner(const Rect.fromLTWH(1500, 10, 240, 400), area), Corner.topRight);
    expect(nearestCorner(const Rect.fromLTWH(10, 600, 240, 400), area), Corner.bottomLeft);
    expect(nearestCorner(const Rect.fromLTWH(900, 500, 240, 400), area), Corner.bottomRight);
    expect(nearestCorner(const Rect.fromLTWH(700, 300, 240, 400), area), Corner.topLeft);
  });
}
