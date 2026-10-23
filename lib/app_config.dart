/// Everything ~/.config/ovos-gui-visage/config.json and the environment decide at startup: the window mode, the
/// face, captions and the language of typed commands. Pure; the desktop reads and writes the file in
/// window/window_shell_io.dart.
library;

import 'face/face_spec.dart';
import 'faults.dart';
import 'window/window_config.dart';

class AppConfig {
  const AppConfig({this.window = const WindowConfig(), this.face = FaceSpec.visage, this.captions = true, this.lang});

  /// [json] is the whole file (or null); [env] wins over it. `face` is a preset name, `eyes+mouth` tokens or an
  /// object (face/face_spec.dart); `VISAGE_FACE` takes the string forms. `captions` (`VISAGE_CAPTIONS`) is a flag;
  /// `lang` (`VISAGE_LANG`) a language tag.
  factory AppConfig.from(Map<String, dynamic>? json, Map<String, String> env) => AppConfig(
    window: WindowConfig.from(json?['window'] as Map<String, dynamic>?, env),
    face: FaceSpec.parse(env['VISAGE_FACE'] ?? json?['face']),
    captions: _flag('captions', env['VISAGE_CAPTIONS'] ?? json?['captions']) ?? true,
    lang: _lang(env['VISAGE_LANG'] ?? json?['lang']),
  );

  final WindowConfig window;
  final FaceSpec face;

  /// Show the heard utterance and the spoken reply as text.
  final bool captions;

  /// The language a typed command is sent in; unset leaves it to OVOS's own default.
  final String? lang;
}

String? _lang(Object? value) => value is String && value.trim().isNotEmpty ? value.trim() : null;

const _onWords = {'1', 'true', 'yes', 'on'};
const _offWords = {'0', 'false', 'no', 'off'};

/// A JSON boolean or one of the on/off words; anything else is reported and treated as unset.
bool? _flag(String name, Object? value) {
  if (value == null || value is bool) return value as bool?;
  final word = '$value'.trim().toLowerCase();
  if (_onWords.contains(word)) return true;
  if (_offWords.contains(word)) return false;
  reportFault('config: $name is not a flag, using the default', ArgumentError.value(value, name));
  return null;
}
