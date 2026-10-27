/// Everything ~/.config/ovos-gui-visage/config.json and the environment decide at startup: the window mode, the
/// face, captions, the language of typed commands and the GUI protocol. Pure; the desktop reads and writes the file in
/// window/window_shell_io.dart.
library;

import 'face/face_spec.dart';
import 'faults.dart';
import 'protocol/wire_protocol.dart';
import 'window/window_config.dart';

class AppConfig {
  const AppConfig({
    this.window = const WindowConfig(),
    this.face = FaceSpec.visage,
    this.captions = true,
    this.lang,
    this.protocol = WireProtocol.auto,
    this.gui1Url,
  });

  /// [json] is the whole file (or null); [env] wins over it. `face` is a preset name, `eyes+mouth` tokens or an
  /// object (face/face_spec.dart); `VISAGE_FACE` takes the string forms. `captions` (`VISAGE_CAPTIONS`) is a flag;
  /// `lang` (`VISAGE_LANG`) a language tag. `protocol` (`VISAGE_PROTOCOL`) is `auto`, `gui1` or `legacy`; `gui1Url`
  /// (`VISAGE_GUI1_URL`) moves the GUI-1 endpoint off the bus host's port 18182.
  factory AppConfig.from(Map<String, dynamic>? json, Map<String, String> env) => AppConfig(
    window: WindowConfig.from(json?['window'] as Map<String, dynamic>?, env),
    face: FaceSpec.parse(env['VISAGE_FACE'] ?? json?['face']),
    captions: _flag('captions', env['VISAGE_CAPTIONS'] ?? json?['captions']) ?? true,
    lang: _lang(env['VISAGE_LANG'] ?? json?['lang']),
    protocol: _protocol(env['VISAGE_PROTOCOL'] ?? json?['protocol']),
    gui1Url: _wsUrl('gui1Url', env['VISAGE_GUI1_URL'] ?? json?['gui1Url']),
  );

  final WindowConfig window;
  final FaceSpec face;

  /// Show the heard utterance and the spoken reply as text.
  final bool captions;

  /// The language a typed command is sent in; unset leaves it to OVOS's own default.
  final String? lang;

  final WireProtocol protocol;

  /// Null leaves the GUI-1 endpoint to the platform (protocol/endpoints.dart).
  final Uri? gui1Url;
}

WireProtocol _protocol(Object? value) {
  try {
    return wireProtocolFrom(value) ?? WireProtocol.auto;
  } on ArgumentError catch (err) {
    reportFault('config: protocol, using auto', err);
    return WireProtocol.auto;
  }
}

/// A `ws://` or `wss://` URL; anything else is reported and treated as unset.
Uri? _wsUrl(String name, Object? value) {
  if (value == null) return null;
  final url = Uri.tryParse('$value'.trim());
  if (url != null && (url.scheme == 'ws' || url.scheme == 'wss') && url.host.isNotEmpty) return url;
  reportFault('config: $name is not a ws:// URL, using the default', ArgumentError.value(value, name));
  return null;
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
