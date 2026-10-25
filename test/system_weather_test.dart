import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/system_weather_page.dart';
import 'package:ovos_gui_visage/pages/weather_card_model.dart';
import 'package:ovos_gui_visage/pages/weather_model.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/weather_icon.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const full = {'current_temp': 21, 'min_temp': 14, 'max_temp': 25.5, 'condition': 'Clear', 'location': 'San Antonio'};

Future<List<String>> pumpFaults(WidgetTester tester, Json data) async {
  final state = replayGui1([template(weather, 'SYSTEM_weather', data)]);
  final faults = await collectFaults(() async {
    await tester.pumpWidget(host(pageOf(state)));
    await tester.pump(const Duration(milliseconds: 100));
  });
  return [for (final fault in faults) '${fault.exception}'];
}

void main() {
  group('model', () {
    test('every key on the card, temperatures as given, no unit', () {
      final card = weatherCard(full);
      expect([card.now.heading, card.now.location, card.now.icon, card.now.big], ['Clear', 'San Antonio', 'sun', '21°']);
      expect(card.now.chips, [(value: '25.5°', label: 'high'), (value: '14°', label: 'low')]);
      expect([card.image, card.problems], [null, isEmpty]);
    });

    test('a missing optional key leaves its element out, without a problem', () {
      final card = weatherCard({'current_temp': -3, 'condition': 'Snow'});
      expect([card.now.big, card.now.location, card.now.chips, card.problems], ['-3°', '', isEmpty, isEmpty]);
    });

    test('a missing required key or a wrong type is a problem; the rest still reads', () {
      final card = weatherCard({'min_temp': '14', 'location': 'Austin'});
      expect(card.problems, [
        'current_temp is required',
        'min_temp must be a finite number, got String 14',
        'condition is required',
      ]);
      expect([card.now.big, card.now.icon, card.now.location, card.now.chips], [missing, unknownIcon, 'Austin', isEmpty]);
    });

    test('icon: an http(s) URL or data:image URI overrides; a bare path or other value is a problem', () {
      expect(weatherCard({...full, 'icon': 'https://x/sun.png'}).image, 'https://x/sun.png');
      expect(weatherCard({...full, 'icon': 'data:image/png;base64,AA=='}).image, 'data:image/png;base64,AA==');
      final path = weatherCard({...full, 'icon': '/opt/skill/sun.png'});
      expect([path.image, path.problems.single], [null, contains('§3.5')]);
      expect(weatherCard({...full, 'icon': 4}).problems.single, 'icon must be a string, got int 4');
    });

    test('condition picks a bundled icon by keyword, unknown text the default', () {
      final icons = {
        'Thunderstorm': 'storm',
        'light snow': 'snow',
        'Showers': 'rain',
        'Mist': 'fog',
        'Partly cloudy': 'partial_clouds',
        'Overcast': 'clouds',
        'Clear night': 'night',
        'Sunny': 'sun',
        'Despejado': unknownIcon,
      };
      expect({for (final c in icons.keys) c: conditionIcon(c)}, icons);
    });
  });

  testWidgets('system_weather fixture: the card shows every key, then the update and its data: icon', (tester) async {
    final frames = loadGui1Fixture('system_weather', note: fromSpec);
    final state = replayGui1(frames.take(3).toList());
    expect(state.current(), const Target(weather, 'SYSTEM_weather', 0));
    expect(resolve(state.current(), gaps: TemplateGaps()), same(SystemWeatherPage.page));
    await tester.pumpWidget(host(pageOf(state)));
    final shown = ['21°', 'Partly cloudy', 'San Antonio', '25.5°', 'high', '14°', 'low'];
    expect(shown.map(find.text), everyElement(findsOneWidget));
    expect(find.byType(WeatherIcon), findsOneWidget);

    replayGui1(frames.skip(3).toList(), state: state);
    await tester.pumpWidget(host(pageOf(state)));
    expect(find.text('22°'), findsOneWidget);
    expect(find.byType(WeatherIcon), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('a missing current_temp is reported and the card keeps the condition', (tester) async {
    final faults = await pumpFaults(tester, {'condition': 'Rain', 'location': 'Austin'});
    expect(faults, ['FormatException: current_temp is required']);
    expect([find.text(missing), find.text('Rain'), find.text('Austin')], everyElement(findsOneWidget));
  });

  testWidgets('a bare path icon is reported and the bundled icon shows', (tester) async {
    final faults = await pumpFaults(tester, {...full, 'icon': 'sun.png'});
    expect(faults.single, contains('icon must be an http(s) URL'));
    expect(find.byType(WeatherIcon), findsOneWidget);
  });
}
