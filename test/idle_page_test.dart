import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/idle_page.dart';
import 'package:ovos_gui_visage/widgets/home_chips.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';

Widget host(Widget page) => MaterialApp(
  home: Material(
    child: Center(child: SizedBox(width: 432, height: 736, child: page)),
  ),
);

GuiState replayFixture(String name) {
  final state = GuiState();
  for (final line in File('test/fixtures/$name').readAsLinesSync()) {
    if (line.trim().isNotEmpty) state.apply(jsonDecode(line) as Json);
  }
  return state;
}

void main() {
  test('weather codes map to the homescreen icon set', () {
    expect(weatherIconName(0), 'sun');
    expect(weatherIconName('5'), 'storm');
    expect(weatherIconName(42), 'clouds');
    expect(weatherIconName(null), 'clouds');
  });

  test('date line follows dateFormat and falls back to date_string', () {
    expect(
      dateLine({'weekday_string': 'Saturday', 'day_string': '17', 'month_string': 'October', 'dateFormat': 'DMY'}),
      'Saturday, 17 October',
    );
    expect(
      dateLine({'weekday_string': 'Saturday', 'day_string': '17', 'month_string': 'October', 'dateFormat': 'MDY'}),
      'Saturday, October 17',
    );
    expect(dateLine({'date_string': '17/10/2026'}), '17/10/2026');
  });

  testWidgets('the badge counts the stored list, not the ever-growing counter, and a tap opens the list', (tester) async {
    var opened = 0;
    final ctx = PageContext(
      namespace: defaultIdleNamespace,
      page: 'idle',
      events: const {},
      storedNotifications: 2,
      showNotifications: () => opened++,
    );
    await tester.pumpWidget(host(IdlePage.page({'time_string': '10:00', 'notifcation_counter': 14}, ctx)));
    expect(find.text('14'), findsNothing);
    await tester.tap(find.byTooltip(showNotificationsLabel));
    expect(opened, 1);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('with nothing stored there is no badge', (tester) async {
    const ctx = PageContext(namespace: defaultIdleNamespace, page: 'idle', events: {});
    await tester.pumpWidget(host(IdlePage.page({'time_string': '10:00', 'notifcation_counter': 3}, ctx)));
    expect(find.byTooltip(showNotificationsLabel), findsNothing);
  });

  testWidgets('a badge with no list wired reports the tap rather than doing nothing', (tester) async {
    const ctx = PageContext(namespace: defaultIdleNamespace, page: 'idle', events: {}, storedNotifications: 1);
    await tester.pumpWidget(host(IdlePage.page({'time_string': '10:00'}, ctx)));
    final faults = await collectFaults(() async => tester.tap(find.byTooltip(showNotificationsLabel)));
    expect('${faults.single.exception}', contains('no shell list'));
  });

  testWidgets('the recorded boot sync renders the idle clock and weather', (tester) async {
    final state = replayFixture('boot_sync_idle.jsonl');
    final ns = state.namespace(defaultIdleNamespace);
    final ctx = PageContext(namespace: defaultIdleNamespace, page: 'idle', events: ns.events);
    await tester.pumpWidget(host(IdlePage.page(ns.data, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(ns.data['time_string'] as String), findsOneWidget);
    expect(find.textContaining('°'), findsOneWidget);
  });

  testWidgets('a timer widget event shows the timer chip', (tester) async {
    const ctx = PageContext(
      namespace: defaultIdleNamespace,
      page: 'idle',
      events: {
        timerEvent: {'count': 2},
      },
    );
    await tester.pumpWidget(host(IdlePage.page({'time_string': '10:00'}, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('timers'), findsOneWidget);
    expect(find.text('alarms'), findsNothing);
  });

  testWidgets('a temperature the parser cannot read hides the weather chip and is reported, never shown as 0', (tester) async {
    Json data(Object temp) => {'weather_api_enabled': true, 'weather_temp': temp, 'weather_code': 0, 'time_string': '09:05'};
    final faults = await collectFaults(() async {
      await tester.pumpWidget(
        host(IdlePage(data: data('n/a'), events: const {}, storedNotifications: 0, onShowNotifications: () {})),
      );
    });
    expect(find.byType(WeatherChip), findsNothing);
    expect(find.text('0°'), findsNothing);
    expect(faults.single.exceptionAsString(), contains('weather_temp'));
    await tester.pumpWidget(
      host(IdlePage(data: data('21,5'), events: const {}, storedNotifications: 0, onShowNotifications: () {})),
    );
    expect(find.text('22°'), findsOneWidget, reason: 'a comma decimal reads as the skill meant it');
  });
}
