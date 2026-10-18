/// Everything ~/.config/ovos-gui-visage/config.json and the environment decide at startup: the window mode and the
/// face theme. Pure; the desktop reads the file in window/window_shell_io.dart.
library;

import 'window/window_config.dart';

const defaultFace = 'visage';

class AppConfig {
  const AppConfig({this.window = const WindowConfig(), this.face = defaultFace});

  /// [json] is the whole file (or null); [env] wins over it.
  factory AppConfig.from(Map<String, dynamic>? json, Map<String, String> env) => AppConfig(
    window: WindowConfig.from(json?['window'] as Map<String, dynamic>?, env),
    face: (env['VISAGE_FACE'] ?? json?['face']?.toString() ?? defaultFace).trim().toLowerCase(),
  );

  final WindowConfig window;

  /// A face theme name for `faceThemes` (face/themes.dart); an unknown name reports and falls back to visage.
  final String face;
}
