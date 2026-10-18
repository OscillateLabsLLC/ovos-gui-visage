import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

void main() {
  test('the face comes from the file, the environment wins, visage is the default', () {
    expect(AppConfig.from(null, const {}).face, 'visage');
    expect(AppConfig.from({'face': 'Mark1'}, const {}).face, 'mark1');
    expect(AppConfig.from({'face': 'mark1'}, const {'VISAGE_FACE': 'visage'}).face, 'visage');
  });

  test('the window object still reaches the window config', () {
    final config = AppConfig.from({
      'window': {'mode': 'float'},
    }, const {});
    expect(config.window.mode, WindowMode.float);
  });
}
