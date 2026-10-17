/// Pure session-data -> view-model mapping for the weather pages (SPEC 8.3), port of weather_model.js.
library;

import '../json.dart';
import 'page.dart';

/// ovos-skill-weather's animated weatherCode switch (WeatherDelegate.qml getWeatherAnimation).
const animatedIcons = [
  'sun', 'night', // 0 clear day, 1 clear night
  'partial_clouds', 'partial_clouds', // 2, 3 few clouds
  'clouds', 'clouds', // 4, 5 scattered clouds
  'partial_clouds', 'partial_clouds', // 6, 7 broken clouds
  'rain', 'rain', 'rain', 'rain', // 8-11 shower rain, rain
  'storm', 'storm', // 12, 13 thunderstorm
  'snow', 'snow', // 14, 15 snow
  'fog', 'fog', // 16, 17 mist
];
const unknownIcon = 'clouds';
const missing = '–';

String animatedIconName(Object? code) {
  if (code == null || code == '') return unknownIcon;
  final index = number(code, -1).toInt();
  return index >= 0 && index < animatedIcons.length ? animatedIcons[index] : unknownIcon;
}

bool _isBlank(Object? value) => value == null || value == '';

double? _numberOrNull(Object? value) =>
    _isBlank(value) ? null : (value is num ? value.toDouble() : double.tryParse(value.toString()));

String degrees(Object? value) {
  final n = _numberOrNull(value);
  return n == null ? missing : '${n.round()}°';
}

String percent(Object? value) {
  final n = _numberOrNull(value);
  return n == null ? missing : '${n.round()}%';
}

String _details(Json data, bool withHumidity) {
  final parts = <String>[];
  if (withHumidity && !_isBlank(data['humidity'])) parts.add('humidity ${percent(data['humidity'])}');
  final wind = _numberOrNull(data['windSpeed']);
  if (wind != null) parts.add('wind ${wind.round()}');
  return parts.join(' · ');
}

typedef WeatherChip = ({String value, String label});

List<WeatherChip> _nowChips(bool single, Json data) {
  final low = (value: degrees(data['lowTemperature']), label: 'low');
  final rain = (value: percent(data['chanceOfPrecipitation']), label: 'rain');
  if (single) return [low, rain, (value: percent(data['humidity']), label: 'humidity')];
  return [(value: degrees(data['highTemperature']), label: 'high'), low, rain];
}

typedef NowModel = ({String heading, String location, String icon, String big, List<WeatherChip> chips, String details});

/// CurrentWeather (big = now) and SingleDay (big = the day's high): one big circle plus three chips.
NowModel nowModel(String page, Json data) {
  final single = page == 'SingleDay';
  return (
    heading: text(single ? data['weatherDate'] : data['currentTimezone']),
    location: text(data['weatherLocation']),
    icon: animatedIconName(data['weatherCode']),
    big: degrees(single ? data['highTemperature'] : data['currentTemperature']),
    chips: _nowChips(single, data),
    details: _details(data, !single),
  );
}

typedef ForecastItem = ({String label, String icon, String main, String sub});

ForecastItem _dailyItem(Map day) => (
  label: text(day['date']),
  icon: animatedIconName(day['weatherCondition']),
  main: degrees(day['highTemperature']),
  sub: degrees(day['lowTemperature']),
);

ForecastItem _hourlyItem(Map hour) => (
  label: text(hour['time']),
  icon: animatedIconName(hour['weatherCondition']),
  main: degrees(hour['temperature']),
  sub: percent(hour['precipitation']),
);

typedef ForecastModel = ({String heading, String location, List<ForecastItem> items, bool hourly});

/// DailyForecast reads forecast.all[], HourlyForecast reads hourlyForecast.hours[] (skill __init__.py builders).
ForecastModel forecastModel(String page, Json data) {
  final hourly = page == 'HourlyForecast';
  final source = hourly ? data['hourlyForecast'] : data['forecast'];
  final raw = source is Map ? source[hourly ? 'hours' : 'all'] : null;
  final items = raw is List ? raw.whereType<Map>().toList() : const <Map>[];
  return (
    heading: hourly ? text(data['currentTimezone']) : '',
    location: text(data['weatherLocation']),
    items: [for (final item in items) hourly ? _hourlyItem(item) : _dailyItem(item)],
    hourly: hourly,
  );
}

typedef SunTimesModel = ({String heading, String location, String sunrise, String sunset});

SunTimesModel sunTimesModel(Json data) => (
  heading: text(data['currentTimezone']),
  location: text(data['weatherLocation']),
  sunrise: _isBlank(data['sunrise']) ? missing : text(data['sunrise']),
  sunset: _isBlank(data['sunset']) ? missing : text(data['sunset']),
);
