import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/alarms_page.dart';
import 'package:ovos_gui_visage/pages/alert_list_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/timer_page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

const alerts = 'ovos-skill-alerts.openvoiceos';
const ctx = PageContext(namespace: alerts, page: 'Timer', events: {});

Widget host(Widget page) => MaterialApp(home: Material(child: Center(child: SizedBox(width: 432, height: 736, child: page))));

/// Every distinct Timer page state in a fixture, in order.
List<Json> timerStates(String fixture) {
  final state = GuiState();
  final states = <Json>[];
  for (final line in File('test/fixtures/$fixture').readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    state.apply(jsonDecode(line) as Json);
    final current = state.current();
    if (current?.namespace == alerts && current?.page == 'Timer') {
      final data = jsonDecode(jsonEncode(state.namespace(alerts).data)) as Json;
      if (data.containsKey('activeTimers') && (states.isEmpty || jsonEncode(states.last) != jsonEncode(data))) states.add(data);
    }
  }
  return states;
}

void main() {
  test('alerts pages are routed', () {
    expect(resolve(const Target(alerts, 'Timer', 0))({}, ctx), isA<TimerPage>());
    expect(resolve(const Target(alerts, 'AlarmsOverviewCard', 0))({}, ctx), isA<AlarmsPage>());
    expect(resolve(const Target(alerts, 'ListView', 0))({}, ctx), isA<AlertListPage>());
  });

  testWidgets('a recorded timer counts down through one page instance and keeps its ring', (tester) async {
    final states = timerStates('alerts_one_timer_cancel.jsonl');
    expect(states.length, greaterThan(2));
    await tester.pumpWidget(host(TimerPage.page(states.first, ctx)));
    await tester.pump(const Duration(seconds: 1));
    final first = tester.widget<TimerRing>(find.byType(TimerRing));
    for (final data in states.skip(1)) {
      await tester.pumpWidget(host(TimerPage.page(data, ctx)));
      await tester.pump(const Duration(seconds: 1));
    }
    final last = tester.widget<TimerRing>(find.byType(TimerRing));
    expect(last.timer.id, first.timer.id);
    expect(last.timer.fraction, lessThan(first.timer.fraction));
    expect(find.text(last.timer.delta), findsOneWidget);
  });

  testWidgets('two timers stack at the smaller size and an expired one reads finished', (tester) async {
    final data = {
      'activeTimers': {
        'timers': [
          {'alertId': 'a', 'timerName': 'eggs', 'timeDelta': '-0:07', 'percentRemaining': 0, 'expired': true},
          {'alertId': 'b', 'timerName': '', 'timeDelta': '2:15', 'percentRemaining': 0.99999, 'expired': false},
        ],
      },
    };
    await tester.pumpWidget(host(TimerPage.page(data, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(TimerRing), findsNWidgets(2));
    expect(tester.widget<TimerRing>(find.byType(TimerRing).first).size, 230);
    expect(find.text(finished), findsOneWidget);
    expect(find.text('+0:07'), findsOneWidget);
    expect(find.text('2:15'), findsOneWidget);
  });

  testWidgets('alarms: chips up to two, a grid beyond, ringing label, +n more', (tester) async {
    Map alarm(int i, {bool expired = false}) =>
        {'alarmIndex': '$i', 'alarmTime': '7:0$i', 'alarmAmPm': 'AM', 'alarmName': 'wake $i', 'alarmRepeatStr': 'Once', 'alarmExpired': expired};
    await tester.pumpWidget(host(AlarmsPage.page({'activeAlarms': [alarm(1, expired: true)]}, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('RINGING'), findsOneWidget);
    expect(find.text('ALARMS'), findsOneWidget);
    await tester.pumpWidget(host(AlarmsPage.page({'activeAlarms': [for (var i = 1; i <= 6; i++) alarm(i)]}, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('+3 more'), findsOneWidget);
    expect(find.byType(Bell), findsNWidgets(3));
    await tester.pumpWidget(host(AlarmsPage.page({}, ctx)));
    expect(find.text('No alarms'), findsOneWidget);
  });

  testWidgets('the list page shows the count, header and rows', (tester) async {
    final data = {'header': 'Reminders', 'items': [{'main': 'stretch', 'secondary': '11:00 PM'}, 'water']};
    await tester.pumpWidget(host(AlertListPage.page(data, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('REMINDERS'), findsOneWidget);
    expect(find.text('stretch'), findsOneWidget);
    expect(find.text('11:00 PM'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);
  });
}
