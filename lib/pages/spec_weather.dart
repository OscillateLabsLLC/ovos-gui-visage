/// The `SYSTEM_weather` keys of [gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue),
/// read and checked: `current_temp` and `condition` required; `min_temp`, `max_temp`, `condition_code`, `icon`,
/// `location` and `forecast` optional. The same keys arrive as `gui.ambient.weather`
/// ([6.9.1 Ambient data](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#691-ambient-data)), so this
/// stays free of widgets and of reporting: every problem is a sentence in [SpecWeather.problems].
library;

import '../json.dart';
import 'spec_keys.dart';

/// The closed `condition_code` set; [wire] is the value on the wire.
enum ConditionCode {
  clear('clear'),
  partlyCloudy('partly_cloudy'),
  cloudy('cloudy'),
  fog('fog'),
  drizzle('drizzle'),
  rain('rain'),
  snow('snow'),
  sleet('sleet'),
  thunder('thunder'),
  wind('wind');

  const ConditionCode(this.wire);

  final String wire;

  static ConditionCode? fromWire(String value) => values.where((code) => code.wire == value).firstOrNull;
}

typedef SpecForecast = ({double time, double? minTemp, double? maxTemp, ConditionCode? code});

typedef SpecWeather = ({
  double? currentTemp,
  double? minTemp,
  double? maxTemp,
  String condition,
  ConditionCode? code,
  String? icon,
  String location,
  List<SpecForecast> forecast,
  List<String> problems,
});

/// [3.5 Image delivery](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#35-image-delivery): an http(s)
/// URL or a data: URI; a bare path is never loaded.
final _imageUri = RegExp(r'^(https?://|data:image/)', caseSensitive: false);

SpecWeather specWeather(Json data) {
  final code = _code(data['condition_code'], 'condition_code');
  final icon = data['icon'], iconProblem = _iconProblem(icon);
  final forecast = _forecast(data['forecast']);
  return (
    currentTemp: finite(data['current_temp']),
    minTemp: finite(data['min_temp']),
    maxTemp: finite(data['max_temp']),
    condition: optionalText(data['condition']),
    code: code.code,
    icon: iconProblem == null && icon is String ? icon : null,
    location: optionalText(data['location']),
    forecast: forecast.entries,
    problems: [
      requiredNumber(data['current_temp'], 'current_temp'),
      optionalNumber(data['min_temp'], 'min_temp'),
      optionalNumber(data['max_temp'], 'max_temp'),
      requiredString(data['condition'], 'condition'),
      code.problem,
      iconProblem,
      optionalString(data['location'], 'location'),
      ...forecast.problems,
    ].nonNulls.toList(),
  );
}

/// An unlisted code is treated as absent, and reported: producers must not send one.
({ConditionCode? code, String? problem}) _code(Object? value, String key) {
  if (value == null) return (code: null, problem: null);
  if (value is! String) return (code: null, problem: optionalString(value, key));
  final code = ConditionCode.fromWire(value);
  return (code: code, problem: code == null ? '$key "$value" is not in the closed set, so it is ignored' : null);
}

String? _iconProblem(Object? icon) {
  if (icon == null) return null;
  if (icon is! String) return optionalString(icon, 'icon');
  return _imageUri.hasMatch(icon) ? null : 'icon must be an http(s) URL or a data:image URI, got $icon';
}

/// Entries without a usable `time` are left out, and reported with every other problem in the array.
({List<SpecForecast> entries, List<String> problems}) _forecast(Object? value) {
  if (value == null) return (entries: const [], problems: const []);
  if (value is! List) return (entries: const [], problems: ['forecast must be an array, got ${value.runtimeType}']);
  final entries = <SpecForecast>[], problems = <String>[];
  for (final (index, raw) in value.indexed) {
    final entry = _forecastEntry(raw, 'forecast[$index]', problems);
    if (entry != null) entries.add(entry);
  }
  final ordered = [for (var i = 1; i < entries.length; i++) entries[i].time > entries[i - 1].time].every((later) => later);
  if (!ordered) problems.add('forecast is not in time order');
  return (entries: entries, problems: problems);
}

SpecForecast? _forecastEntry(Object? raw, String at, List<String> problems) {
  if (raw is! Map) {
    problems.add('$at must be an object, got ${raw.runtimeType}');
    return null;
  }
  final timeProblem = requiredNumber(raw['time'], '$at.time');
  final code = _code(raw['condition_code'], '$at.condition_code');
  problems.addAll(
    [
      timeProblem,
      optionalNumber(raw['min_temp'], '$at.min_temp'),
      optionalNumber(raw['max_temp'], '$at.max_temp'),
      code.problem,
    ].nonNulls,
  );
  if (timeProblem != null) return null;
  return (time: finite(raw['time'])!, minTemp: finite(raw['min_temp']), maxTemp: finite(raw['max_temp']), code: code.code);
}
