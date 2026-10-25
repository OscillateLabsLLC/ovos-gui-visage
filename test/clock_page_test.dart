import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/clock_page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const dateTime = 'ovos-skill-date-time.openvoiceos';

Widget withHourFormat(Widget page, {required bool use24Hour}) => MediaQuery(
  data: MediaQueryData(alwaysUse24HourFormat: use24Hour),
  child: host(page),
);

void main() {
  test('clock view: 24-hour and 12-hour forms, noon and midnight', () {
    final evening = DateTime(2026, 10, 25, 21, 5);
    expect(clockView(evening, use24Hour: true), (time: '21:05', ampm: '', date: 'Sunday, 25 October'));
    expect(clockView(evening, use24Hour: false), (time: '9:05', ampm: 'PM', date: 'Sunday, 25 October'));
    expect(clockView(DateTime(2026, 10, 25, 0, 7), use24Hour: false).time, '12:07');
    expect(clockView(DateTime(2026, 10, 25, 0, 7), use24Hour: false).ampm, 'AM');
    expect(clockView(DateTime(2026, 10, 25, 12), use24Hour: false).ampm, 'PM');
    expect(clockView(DateTime(2026, 10, 25, 7, 3), use24Hour: true).time, '07:03');
  });

  testWidgets('system_clock fixture: the clock page shows the device time and ticks by itself', (tester) async {
    final state = replayGui1(loadGui1Fixture('system_clock'));
    expect(state.current(), const Target(dateTime, 'SYSTEM_clock', 0));
    expect(resolve(state.current(), gaps: TemplateGaps()), same(ClockPage.page));
    await tester.pumpWidget(host(pageOf(state)));
    expect(find.byType(ClockPage), findsOneWidget);

    var now = DateTime(2026, 10, 25, 9, 59, 59);
    await tester.pumpWidget(withHourFormat(ClockPage(now: () => now), use24Hour: false));
    expect([find.text('9:59'), find.text('AM'), find.text('Sunday, 25 October')], everyElement(findsOneWidget));
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('10:00'), findsOneWidget);
  });

  testWidgets('a 24-hour device shows no am/pm line', (tester) async {
    await tester.pumpWidget(withHourFormat(ClockPage(now: () => DateTime(2026, 10, 25, 21, 5)), use24Hour: true));
    expect(find.text('21:05'), findsOneWidget);
    expect(find.text('PM'), findsNothing);
  });

  testWidgets('session data the template does not define is ignored, without a report', (tester) async {
    final state = replayGui1([
      template(dateTime, 'SYSTEM_clock', {'time_string': '1:23', 'format': '24h'}),
    ]);
    final faults = await collectFaults(() async {
      await tester.pumpWidget(host(pageOf(state)));
      await tester.pump(const Duration(seconds: 1));
    });
    expect(faults, isEmpty);
    expect(find.text('1:23'), findsNothing);
  });
}
