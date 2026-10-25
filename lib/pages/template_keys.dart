/// Typed reads of GUI-1 session-data keys (gui-1.md 3.3 Session-data typing rules) for the template view models. A
/// missing required key or a value of the wrong type is a protocol fault: reported once per template, key and value,
/// and then read as the nearest usable value so the page still renders (gui-1.md 6.5).
library;

import 'package:flutter/foundation.dart';

import '../faults.dart';
import '../json.dart';

final _reported = <String>{};
final _imageUrl = RegExp(r'^(https?://|data:image/)', caseSensitive: false);

/// Lets each test see its own reports; the app never forgets a report.
@visibleForTesting
void forgetReportedKeys() => _reported.clear();

void reportKey(String template, String key, String problem) {
  if (!_reported.add('$template.$key: $problem')) return;
  reportFault('$template data', FormatException('$key $problem'));
}

String _describe(Object value) => '${value.runtimeType} $value';

/// A string key. A number or a boolean is reported and shown as its text; any other type is reported and dropped.
String readText(String template, Json data, String key, {bool required = false}) {
  final value = data[key];
  if (value is String) return value;
  if (value == null) {
    if (required) reportKey(template, key, 'is required');
    return '';
  }
  reportKey(template, key, 'must be a string, got ${_describe(value)}');
  return value is num || value is bool ? '$value' : '';
}

/// An array key, or null when it is absent or not an array (reported, as is a missing required one).
List<Object?>? readList(String template, Json data, String key, {bool required = false}) {
  final value = data[key];
  if (value is List) return value;
  if (value == null) {
    if (required) reportKey(template, key, 'is required');
    return null;
  }
  reportKey(template, key, 'must be an array, got ${_describe(value)}');
  return null;
}

/// An image key per gui-1.md 3.5 Image delivery: an `http(s)` URL or a `data:image/` URI, else null. A bare
/// filesystem path or anything else is reported, and the caller renders without the image.
String? readImage(String template, Json data, String key, {bool required = false}) {
  final value = readText(template, data, key, required: required).trim();
  if (value.isEmpty) return null;
  if (_imageUrl.hasMatch(value)) return value;
  reportKey(template, key, 'must be an http(s) URL or a data:image URI (gui-1.md 3.5 Image delivery), got $value');
  return null;
}

/// The objects in an array of items; an entry that is not an object is reported and skipped.
List<Json> readItems(String template, List<Object?> items, String key) => [
  for (final (i, item) in items.indexed)
    if (item is Map<String, dynamic>) item else ?_skip(template, '$key[$i]', item),
];

Json? _skip(String template, String key, Object? item) {
  reportKey(template, key, 'must be an object, got ${item == null ? 'null' : _describe(item)}');
  return null;
}
