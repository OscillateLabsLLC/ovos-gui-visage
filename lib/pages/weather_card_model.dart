/// SYSTEM_weather (gui-1.md §3.4, line 261): `current_temp` and `condition` required; `min_temp`, `max_temp`, `icon`,
/// `location` optional. Mapped onto the skill's current-weather card (weather_model.dart). Pure.
library;

import '../json.dart';
import 'data_faults.dart';
import 'weather_model.dart';

/// `condition` is free text (finding F18), so the bundled icon is chosen by English keywords, first match wins;
/// anything else gets [unknownIcon].
const _conditionIcons = [
  (words: ['thunder', 'storm', 'lightning'], icon: 'storm'),
  (words: ['snow', 'sleet', 'flurr', 'blizzard', 'hail'], icon: 'snow'),
  (words: ['rain', 'drizzle', 'shower'], icon: 'rain'),
  (words: ['fog', 'mist', 'haze', 'smoke', 'dust'], icon: 'fog'),
  (words: ['partly', 'partial', 'few', 'scattered', 'broken', 'intervals'], icon: 'partial_clouds'),
  (words: ['cloud', 'overcast'], icon: 'clouds'),
  (words: ['night'], icon: 'night'),
  (words: ['clear', 'sun', 'fair'], icon: 'sun'),
];

/// §3.5: an image key is an http(s) URL or a data: URI; a bare path is never loaded.
final _imageUri = RegExp(r'^(https?://|data:image/)', caseSensitive: false);

String conditionIcon(String condition) {
  final lower = condition.toLowerCase();
  for (final entry in _conditionIcons) {
    if (entry.words.any(lower.contains)) return entry.icon;
  }
  return unknownIcon;
}

/// The temperature as the producer sent it, whole numbers without a decimal point, and no unit (finding F17).
String temperature(double? value) {
  if (value == null) return missing;
  return value == value.roundToDouble() ? '${value.round()}°' : '$value°';
}

String? _iconProblem(Object? icon) {
  if (icon == null) return null;
  if (icon is! String) return optionalString(icon, 'icon');
  return _imageUri.hasMatch(icon) ? null : 'icon must be an http(s) URL or a data:image URI (§3.5), got $icon';
}

typedef WeatherCard = ({NowModel now, String? image, List<String> problems});

WeatherCard weatherCard(Json data) {
  final current = data['current_temp'], low = finite(data['min_temp']), high = finite(data['max_temp']);
  final condition = data['condition'], icon = data['icon'];
  return (
    now: (
      heading: optionalText(condition),
      location: optionalText(data['location']),
      icon: conditionIcon(optionalText(condition)),
      big: temperature(finite(current)),
      chips: [
        if (high != null) (value: temperature(high), label: 'high'),
        if (low != null) (value: temperature(low), label: 'low'),
      ],
      details: '',
    ),
    image: _iconProblem(icon) == null && icon is String ? icon : null,
    problems: [
      requiredNumber(current, 'current_temp'),
      optionalNumber(data['min_temp'], 'min_temp'),
      optionalNumber(data['max_temp'], 'max_temp'),
      requiredString(condition, 'condition'),
      _iconProblem(icon),
      optionalString(data['location'], 'location'),
    ].nonNulls.toList(),
  );
}
