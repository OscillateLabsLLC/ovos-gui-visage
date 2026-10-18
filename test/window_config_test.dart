import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

void main() {
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
}
