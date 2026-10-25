/// Checks for session-data keys against a template's key list in
/// [gui-1.md 3.3 Session-data typing rules](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#33-session-data-typing-rules)
/// and [3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue). Each check
/// returns a problem sentence, or null when the value is fine. Pure: no widgets, no reporting.
library;

/// The problem when a required string key is absent or not a string.
String? requiredString(Object? value, String key) => value is String ? null : _typeProblem(key, 'a string', value);

/// The problem when an optional string key is present and not a string.
String? optionalString(Object? value, String key) =>
    value == null || value is String ? null : _typeProblem(key, 'a string', value);

/// The problem when a required number key is absent or not a finite number.
String? requiredNumber(Object? value, String key) => _isFinite(value) ? null : _typeProblem(key, 'a finite number', value);

/// The problem when an optional number key is present and not a finite number.
String? optionalNumber(Object? value, String key) => value == null ? null : requiredNumber(value, key);

/// The problem when an optional boolean key is present and not a boolean.
String? optionalBool(Object? value, String key) => value == null || value is bool ? null : _typeProblem(key, 'a boolean', value);

/// [value] as a double when it is a finite number, else null.
double? finite(Object? value) => _isFinite(value) ? (value as num).toDouble() : null;

/// An optional string key as text, or '' when it is absent or of the wrong type (reported by [optionalString]).
String optionalText(Object? value) => value is String ? value : '';

bool _isFinite(Object? value) => value is num && value.isFinite;

String _typeProblem(String key, String expected, Object? value) =>
    value == null ? '$key is required' : '$key must be $expected, got ${value.runtimeType} $value';
