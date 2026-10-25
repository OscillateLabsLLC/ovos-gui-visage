/// What the SYSTEM_weather page shows from a [SpecWeather]: current conditions on the skill's current-weather card
/// (weather_model.dart `NowModel`), and up to [maxForecastShown] forecast entries beneath it as the forecast page's
/// small circles, in one screen. The icon comes from `condition_code`; a valid `icon` replaces it; with neither, the
/// condition text shows with no icon. Pure.
library;

import 'spec_weather.dart';
import 'weather_model.dart';

/// `wind` has no glyph in the bundled set, so it shows the text alone.
const codeIcons = {
  ConditionCode.clear: 'sun',
  ConditionCode.partlyCloudy: 'partial_clouds',
  ConditionCode.cloudy: 'clouds',
  ConditionCode.fog: 'fog',
  ConditionCode.drizzle: 'rain',
  ConditionCode.rain: 'rain',
  ConditionCode.snow: 'snow',
  ConditionCode.sleet: 'snow',
  ConditionCode.thunder: 'storm',
};

/// Three 108 px circles and their gaps fit the 432 px page; a fourth does not.
const maxForecastShown = 3;
const noIcon = '';
const _secondsPerDay = 86400;
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String codeIcon(ConditionCode? code) => codeIcons[code] ?? noIcon;

/// The temperature as the producer sent it, whole numbers without a decimal point, and no unit (finding F21).
String temperature(double? value) {
  if (value == null) return missing;
  return value == value.roundToDouble() ? '${value.round()}°' : '$value°';
}

typedef WeatherCard = ({NowModel now, String? image, List<ForecastItem> forecast});

WeatherCard weatherCard(SpecWeather weather, {required bool use24Hour}) {
  final high = weather.maxTemp, low = weather.minTemp;
  return (
    now: (
      heading: weather.condition,
      location: weather.location,
      icon: codeIcon(weather.code),
      big: temperature(weather.currentTemp),
      chips: [
        if (high != null) (value: temperature(high), label: 'high'),
        if (low != null) (value: temperature(low), label: 'low'),
      ],
      details: '',
    ),
    image: weather.icon,
    forecast: forecastItems(weather.forecast, use24Hour: use24Hour),
  );
}

/// Entries closer than a day apart are labelled by hour, others by weekday: the spec gives no period length
/// (finding F32). Times are shown in the device's time zone.
List<ForecastItem> forecastItems(List<SpecForecast> entries, {required bool use24Hour}) {
  final shown = entries.take(maxForecastShown).toList();
  final hourly = shown.length > 1 && shown[1].time - shown[0].time < _secondsPerDay;
  return [
    for (final entry in shown)
      (
        label: periodLabel(entry.time, hourly: hourly, use24Hour: use24Hour),
        icon: codeIcon(entry.code),
        main: temperature(entry.maxTemp),
        sub: temperature(entry.minTemp),
      ),
  ];
}

String _two(int value) => value.toString().padLeft(2, '0');

/// `Mon`, or the hour: `15:00` on a 24-hour device, `3 PM` (or `3:30 PM`) on a 12-hour one.
String periodLabel(double unixSeconds, {required bool hourly, required bool use24Hour}) {
  final start = DateTime.fromMillisecondsSinceEpoch((unixSeconds * 1000).round());
  if (!hourly) return _weekdays[start.weekday - 1];
  if (use24Hour) return '${_two(start.hour)}:${_two(start.minute)}';
  final hour = start.hour % 12 == 0 ? 12 : start.hour % 12;
  final minutes = start.minute == 0 ? '' : ':${_two(start.minute)}';
  return '$hour$minutes ${start.hour < 12 ? 'AM' : 'PM'}';
}
