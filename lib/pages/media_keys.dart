/// Typed reads of the GUI-1 media templates' session data ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue),
/// [3.3 Session-data typing rules](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#33-session-data-typing-rules)). A required key that is missing,
/// or a key of the wrong type, is reported and read as absent or coerced, so the page still shows the nearest useful
/// view ([6.5 Capability and graceful degradation](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#65-capability-and-graceful-degradation)).
/// Each template, key and problem is reported once per run, since a player updates its data every second.
library;

import 'package:flutter/foundation.dart';

import '../faults.dart';
import '../json.dart';

final _told = <String>{};

/// Lets a test see a report its neighbour already caused.
@visibleForTesting
void forgetMediaFaults() => _told.clear();

/// [gui-1.md 3.5 Image delivery](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#35-image-delivery): an image is an http(s) URL or a
/// data: URI, never a path on the producer's machine.
final _wireImage = RegExp(r'^(data:|https?://)', caseSensitive: false);

class MediaKeys {
  const MediaKeys(this.template, this.data, {this.prefix = ''});

  final String template;
  final Json data;

  /// `media_` for SYSTEM_media_player, whose keys all carry it.
  final String prefix;

  Object? _raw(String key) => data['$prefix$key'];

  void fault(String key, String problem, Object? value) {
    final name = '$prefix$key';
    if (!_told.add('$template.$name: $problem')) return;
    reportFault('$template data', FormatException('$name $problem, got ${value.runtimeType} $value'));
  }

  String? string(String key, {bool required = false}) {
    final value = _raw(key);
    if (value == null) {
      if (required) fault(key, 'is required', value);
      return null;
    }
    if (value is String) return value;
    fault(key, 'must be a string', value);
    return '$value';
  }

  /// A finite JSON number; anything else is reported and read as absent.
  double? number(String key) {
    final value = _raw(key);
    if (value == null) return null;
    if (value is num && value.isFinite) return value.toDouble();
    fault(key, 'must be a finite number', value);
    return null;
  }

  bool? flag(String key) {
    final value = _raw(key);
    if (value == null || value is bool) return value as bool?;
    fault(key, 'must be a boolean', value);
    return value == 'true' || (value is num && value != 0);
  }

  /// An array of objects; a non-array is reported and read as empty, a non-object entry is reported and skipped.
  List<Map> items(String key) {
    final value = _raw(key);
    if (value == null) return const [];
    if (value is! List) {
      fault(key, 'must be an array', value);
      return const [];
    }
    final entries = value.whereType<Map>().toList();
    if (entries.length != value.length) fault(key, 'must hold only objects', value);
    return entries;
  }

  /// An image a display may load under image delivery; a path or other scheme is reported and dropped.
  String? image(String key) {
    final value = string(key);
    if (value == null || value.isEmpty) return null;
    if (_wireImage.hasMatch(value)) return value;
    fault(key, 'must be an http(s) URL or a data: URI', value);
    return null;
  }
}
