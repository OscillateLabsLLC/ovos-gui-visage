import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/date_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/time_page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

const ctx = PageContext(namespace: 'ovos-skill-date-time.openvoiceos', page: 'time', events: {});

Widget host(Widget page) => MaterialApp(
  home: Material(child: SizedBox(width: 480, height: 800, child: page)),
);

void main() {
  test('date-time pages are routed', () {
    expect(resolve(const Target('ovos-skill-date-time.openvoiceos', 'time', 0))({}, ctx), isA<TimePage>());
    expect(resolve(const Target('ovos-skill-date-time.openvoiceos', 'date', 0))({}, ctx), isA<DatePage>());
  });

  testWidgets('time page shows the time, am/pm and date', (tester) async {
    await tester.pumpWidget(host(TimePage.page({'time_string': '9:59', 'ampm_string': 'PM', 'date_string': '17/10/2026'}, ctx)));
    expect(find.text('9:59'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);
    expect(find.text('17/10/2026'), findsOneWidget);
    await tester.pumpWidget(host(TimePage.page({}, ctx)));
    expect(find.text('--:--'), findsOneWidget);
  });

  test('a trailing AM/PM in time_string moves to the am/pm line', () {
    expect(timeParts({'time_string': '12:15 PM'}), (time: '12:15', ampm: 'PM'));
    expect(timeParts({'time_string': '9:05 am', 'ampm_string': ''}), (time: '9:05', ampm: 'AM'));
    expect(timeParts({'time_string': '21:05'}), (time: '21:05', ampm: ''));
    expect(timeParts({'time_string': '9:05', 'ampm_string': 'PM'}), (time: '9:05', ampm: 'PM'));
  });

  testWidgets('date page hides the Python None location', (tester) async {
    final data = {
      'weekday_string': 'saturday',
      'daymonth_string': 'october 17',
      'year_string': '2026',
      'location_string': 'None',
    };
    await tester.pumpWidget(host(DatePage.page(data, ctx)));
    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('October 17'), findsOneWidget);
    expect(find.text('None'), findsNothing);
    await tester.pumpWidget(host(DatePage.page({...data, 'location_string': 'San Antonio'}, ctx)));
    expect(find.text('San Antonio'), findsOneWidget);
  });

  test('location and capitalisation helpers', () {
    expect(locationLine('None'), '');
    expect(locationLine(null), '');
    expect(locationLine('Austin'), 'Austin');
    expect(capitalize(''), '');
    expect(capitalize('monday'), 'Monday');
  });
}
