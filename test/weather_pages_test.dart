// Port of the weather assertions in tests/test_skill_pages.py, from the recorded fixtures.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/forecast_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/sun_times_page.dart';
import 'package:ovos_gui_visage/pages/weather_model.dart';
import 'package:ovos_gui_visage/pages/weather_now_page.dart';
import 'package:ovos_gui_visage/widgets/icon_layers.g.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

const weather = 'ovos-skill-weather.openvoiceos';

/// The weather namespace's data as it stood while [page] was on screen (the skill deletes its keys when it leaves).
Json weatherData(String fixture, String page) {
  final state = GuiState();
  Json? shown;
  for (final line in File('test/fixtures/$fixture').readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    state.apply(jsonDecode(line) as Json);
    final current = state.current();
    final data = state.namespace(weather).data;
    // Keys are deleted one by one before the namespace leaves, so keep the fullest state seen while shown.
    if (current?.namespace == weather && current?.page == page && data.length >= (shown?.length ?? 0)) {
      shown = jsonDecode(jsonEncode(data)) as Json;
    }
  }
  return shown ?? (throw StateError('$page never shown in $fixture'));
}

Widget host(Widget page) => MaterialApp(
  home: Material(
    child: Center(child: SizedBox(width: 432, height: 736, child: page)),
  ),
);

void main() {
  test('animated codes follow WeatherDelegate and every icon is bundled', () {
    final icons = [for (var code = 0; code < 18; code++) animatedIconName(code)];
    expect(icons.sublist(0, 2), ['sun', 'night']);
    expect(icons.sublist(8, 12), ['rain', 'rain', 'rain', 'rain']);
    expect(icons.sublist(16), ['fog', 'fog']);
    expect(animatedIconName(99), 'clouds');
    expect(animatedIconName(null), 'clouds');
    for (final name in icons.toSet()) {
      expect(iconLayers.containsKey(name), isTrue, reason: name);
    }
  });

  test('current weather model from live data', () {
    final model = nowModel('CurrentWeather', weatherData('weather_current_hourly_daily.jsonl', 'CurrentWeather'));
    expect(model.icon, 'sun');
    expect(model.big, '22°');
    expect(model.chips.map((c) => c.value), ['30°', '15°', '0%']);
    expect(model.location, 'San Antonio, United States');
  });

  test('forecast models from live data', () {
    final daily = forecastModel('DailyForecast', weatherData('weather_current_hourly_daily.jsonl', 'DailyForecast')).items;
    final hourly = forecastModel('HourlyForecast', weatherData('weather_current_hourly_daily.jsonl', 'HourlyForecast')).items;
    expect(daily.map((i) => i.label), ['Sun', 'Mon', 'Tue', 'Wed']);
    expect(daily[2], (label: 'Tue', icon: 'rain', main: '33°', sub: '22°'));
    expect(hourly.length, 4);
    expect(hourly[0].label, '23:00');
    expect(hourly[0].sub, '0%');
  });

  test('single day and sunset models from live data', () {
    final single = nowModel('SingleDay', weatherData('weather_single_day.jsonl', 'SingleDay'));
    expect(single.heading, 'Sun, 11 October');
    expect(single.icon, 'partial_clouds');
    expect(single.big, '32°');
    expect(single.chips.map((c) => c.value), ['18°', '3%', '51%']);
    expect(single.details, 'wind 7');
    final sun = sunTimesModel(weatherData('weather_sunset_over_timer.jsonl', 'SunriseSunset'));
    expect((sun.sunrise, sun.sunset), ('07:25', '18:49'));
  });

  test('degrees and percent tolerate blanks and strings', () {
    expect(degrees(null), missing);
    expect(degrees('21.6'), '22°');
    expect(percent(''), missing);
    expect(percent(3.4), '3%');
  });

  testWidgets('the weather pages render from the fixtures', (tester) async {
    for (final page in ['CurrentWeather', 'DailyForecast', 'HourlyForecast']) {
      final data = weatherData('weather_current_hourly_daily.jsonl', page);
      final ctx = PageContext(namespace: weather, page: page, events: const {});
      await tester.pumpWidget(host(resolve(Target(weather, page, 0))(data, ctx)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('San Antonio, United States'), findsOneWidget, reason: page);
    }
    expect(find.byType(ForecastPage), findsOneWidget);
    final sunCtx = PageContext(namespace: weather, page: 'SunriseSunset', events: const {});
    await tester.pumpWidget(host(SunTimesPage.page(weatherData('weather_sunset_over_timer.jsonl', 'SunriseSunset'), sunCtx)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('07:25'), findsOneWidget);
    expect(find.text('SUNSET'), findsOneWidget);
    expect(find.byType(WeatherNowPage), findsNothing);
  });
}
