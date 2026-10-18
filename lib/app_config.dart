/// Everything ~/.config/ovos-gui-visage/config.json and the environment decide at startup: the window mode and the
/// face. Pure; the desktop reads and writes the file in window/window_shell_io.dart.
library;

import 'face/face_spec.dart';
import 'window/window_config.dart';

class AppConfig {
  const AppConfig({this.window = const WindowConfig(), this.face = FaceSpec.visage});

  /// [json] is the whole file (or null); [env] wins over it. `face` is a preset name, `eyes+mouth` tokens or an
  /// object (face/face_spec.dart); `VISAGE_FACE` takes the string forms.
  factory AppConfig.from(Map<String, dynamic>? json, Map<String, String> env) => AppConfig(
    window: WindowConfig.from(json?['window'] as Map<String, dynamic>?, env),
    face: FaceSpec.parse(env['VISAGE_FACE'] ?? json?['face']),
  );

  final WindowConfig window;
  final FaceSpec face;
}
