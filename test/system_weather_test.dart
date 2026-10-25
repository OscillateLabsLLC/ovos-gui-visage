import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/forecast_page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/spec_weather.dart';
import 'package:ovos_gui_visage/pages/system_weather_page.dart';
import 'package:ovos_gui_visage/pages/weather_card_model.dart';
import 'package:ovos_gui_visage/pages/weather_model.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/weather_icon.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const full = {'current_temp': 21, 'min_temp': 14, 'max_temp': 25.5, 'condition': 'Clear', 'condition_code': 'clear'};

double unix(DateTime local) => local.millisecondsSinceEpoch / 1000;

String weekday(double seconds) =>
    ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round()).weekday - 1];

Future<List<String>> pumpFaults(WidgetTester tester, Json data) async {
  final state = replayGui1([template(weather, 'SYSTEM_weather', data)]);
  final faults = await collectFaults(() async {
    await tester.pumpWidget(host(pageOf(state)));
    await tester.pump(const Duration(milliseconds: 100));
  });
  return [for (final fault in faults) '${fault.exception}'];
}

void main() {
  group('card model', () {
    test('current conditions on the card: temperatures as given, no unit, the code picks the icon', () {
      final card = weatherCard(specWeather({...full, 'location': 'San Antonio'}), use24Hour: true);
      expect([card.now.heading, card.now.location, card.now.icon, card.now.big], ['Clear', 'San Antonio', 'sun', '21°']);
      expect(card.now.chips, [(value: '25.5°', label: 'high'), (value: '14°', label: 'low')]);
      expect([card.image, card.forecast], [null, isEmpty]);
    });

    test('every condition_code maps to a bundled icon except wind; no code means no icon', () {
      expect(
        {for (final code in ConditionCode.values) code.wire: codeIcon(code)},
        {
          'clear': 'sun',
          'partly_cloudy': 'partial_clouds',
          'cloudy': 'clouds',
          'fog': 'fog',
          'drizzle': 'rain',
          'rain': 'rain',
          'snow': 'snow',
          'sleet': 'snow',
          'thunder': 'storm',
          'wind': noIcon,
        },
      );
      expect(weatherCard(specWeather({'current_temp': 3, 'condition': 'Sunny'}), use24Hour: true).now.icon, noIcon);
    });

    test('forecast: at most three entries; a day apart by weekday, closer by hour', () {
      final monday = DateTime(2026, 10, 26);
      final days = [
        for (var i = 0; i < 6; i++) (time: unix(monday.add(Duration(days: i))), minTemp: 10.0, maxTemp: 20.0, code: null),
      ];
      final daily = forecastItems(days, use24Hour: true);
      expect(daily.map((item) => item.label), ['Mon', 'Tue', 'Wed']);
      expect([daily.first.main, daily.first.sub, daily.first.icon], ['20°', '10°', noIcon]);
      final hours = [
        for (final h in [15, 18]) (time: unix(DateTime(2026, 10, 26, h)), minTemp: null, maxTemp: null, code: null),
      ];
      expect(forecastItems(hours, use24Hour: true).map((item) => item.label), ['15:00', '18:00']);
      expect(forecastItems(hours, use24Hour: false).map((item) => item.label), ['3 PM', '6 PM']);
      expect(periodLabel(unix(DateTime(2026, 10, 26, 0, 30)), hourly: true, use24Hour: false), '12:30 AM');
    });
  });

  testWidgets('system_weather fixture: conditions and forecast, the data: icon, then an unlisted code', (tester) async {
    tester.view
      ..physicalSize = const Size(480, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final frames = loadGui1Fixture('system_weather');
    final state = replayGui1(frames.take(3).toList());
    expect(state.current(), const Target(weather, 'SYSTEM_weather', 0));
    expect(resolve(state.current(), gaps: TemplateGaps()), same(SystemWeatherPage.page));
    await tester.pumpWidget(host(pageOf(state)));
    final shown = ['21°', 'Partly cloudy', 'San Antonio', '25.5°', 'high', '14°', 'low', '27°', '24°', '19°'];
    expect(shown.map(find.text), everyElement(findsOneWidget));
    expect(find.byType(ForecastCircle), findsNWidgets(3));
    expect(find.text(weekday(1793001600)), findsOneWidget);
    expect(find.byType(WeatherIcon), findsNWidgets(4), reason: 'partly cloudy now; clear, rain and thunder ahead');

    replayGui1([frames[3]], state: state);
    await tester.pumpWidget(host(pageOf(state)));
    expect(find.text('22°'), findsOneWidget);
    expect(find.byType(WeatherIcon), findsNothing);
    expect(find.byType(Image), findsOneWidget);

    replayGui1([frames[4]], state: state);
    final faults = await collectFaults(() async => tester.pumpWidget(host(pageOf(state))));
    expect(faults.map((f) => '${f.exception}'), [
      'FormatException: condition_code "hurricane" is not in the closed set, so it is ignored',
    ]);
    expect([find.text('23°'), find.text('Hurricane')], everyElement(findsOneWidget));
    expect([find.byType(WeatherIcon), find.byType(Image), find.byType(ForecastCircle)], everyElement(findsNothing));
  });

  testWidgets('a missing current_temp is reported and the card keeps the condition', (tester) async {
    final faults = await pumpFaults(tester, {'condition': 'Rain', 'condition_code': 'rain', 'location': 'Austin'});
    expect(faults, ['FormatException: current_temp is required']);
    expect([find.text(missing), find.text('Rain'), find.text('Austin')], everyElement(findsOneWidget));
  });

  testWidgets('an unlisted condition_code is reported; the text shows with no icon', (tester) async {
    final faults = await pumpFaults(tester, {...full, 'condition': 'Hurricane', 'condition_code': 'hurricane'});
    expect(faults.single, contains('not in the closed set'));
    expect(find.text('Hurricane'), findsOneWidget);
    expect(find.byType(WeatherIcon), findsNothing);
  });

  testWidgets('a bare path icon is reported and the condition_code icon shows', (tester) async {
    final faults = await pumpFaults(tester, {...full, 'icon': 'sun.png'});
    expect(faults.single, contains('icon must be an http(s) URL'));
    expect(find.byType(WeatherIcon), findsOneWidget);
  });
}
