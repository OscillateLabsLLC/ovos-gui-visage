import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/alarms_page.dart';
import 'package:ovos_gui_visage/pages/alert_controls.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/timer_page.dart';

import 'faults.dart';

const alerts = 'ovos-skill-alerts.openvoiceos';

const timerA = {'alertId': 't1', 'timerName': 'Tea', 'timeDelta': '1:00', 'percentRemaining': 0.5, 'expired': false};
const timerB = {'alertId': 't2', 'timerName': 'Eggs', 'timeDelta': '-0:05', 'percentRemaining': 0, 'expired': true};
const timers = {
  'activeTimers': {
    'timers': [timerA, timerB],
  },
};

const ringing = {'alarmIndex': 'a1', 'alarmName': 'Wake up', 'alarmTime': '7:00', 'alarmAmPm': 'AM', 'alarmExpired': true};
const pending = {'alarmIndex': 'a2', 'alarmName': 'Gym', 'alarmTime': '6:00', 'alarmAmPm': 'PM', 'alarmExpired': false};
const alarms = {
  'activeAlarms': [ringing, pending],
  'activeAlarmCount': 2,
};

Widget host(Widget page) => MaterialApp(
  home: Material(
    child: Center(child: SizedBox(width: 432, height: 650, child: page)),
  ),
);

PageContext recording(String page, List<Json> sent) => PageContext(
  namespace: alerts,
  page: page,
  events: const {},
  send: (message) {
    sent.add(message);
    return true;
  },
);

void main() {
  test('a timer cancel carries the whole timer, as TimerCard.qml sends it', () {
    expect(cancelTimerParameters(timers, 't2'), {'timer': timerB});
    expect(cancelTimerParameters(timers, 'gone'), isNull);
    expect(cancelTimerParameters({}, 't1'), isNull);
  });

  test('an alarm action carries its index, the overview context and its name, as AlarmButtonView.qml sends them', () {
    expect(alarmParameters(alarms, 'a1'), {'alarmIndex': 'a1', 'alarmContext': 'overview', 'alarmName': 'Wake up'});
    expect(alarmParameters(alarms, 'gone'), isNull);
  });

  testWidgets('each timer has a cancel button that sends ovos.alerts.cancel_timer', (tester) async {
    final sent = <Json>[];
    await tester.pumpWidget(host(TimerPage.page(timers, recording('Timer', sent))));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byTooltip('Cancel timer'));
    await tester.tap(find.byTooltip('Dismiss timer'));
    expect(sent, [
      {
        'type': 'mycroft.events.triggered',
        'namespace': alerts,
        'event_name': cancelTimer,
        'parameters': {'timer': timerA},
      },
      {
        'type': 'mycroft.events.triggered',
        'namespace': alerts,
        'event_name': cancelTimer,
        'parameters': {'timer': timerB},
      },
    ]);
  });

  testWidgets('a ringing alarm offers Snooze and Dismiss; a pending one only Cancel', (tester) async {
    final sent = <Json>[];
    await tester.pumpWidget(host(AlarmsPage.page(alarms, recording('AlarmsOverviewCard', sent))));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Snooze'), findsOneWidget);
    await tester.tap(find.text('Snooze'));
    await tester.tap(find.text('Dismiss'));
    await tester.tap(find.text('Cancel'));
    expect([for (final m in sent) m['event_name']], [snoozeAlarm, cancelAlarm, cancelAlarm]);
    expect([for (final m in sent) m['parameters']['alarmIndex']], ['a1', 'a1', 'a2']);
  });

  testWidgets('an item gone from the session data is reported, not sent', (tester) async {
    final sent = <Json>[];
    final faults = await collectFaults(() async => sendAlertEvent(recording('Timer', sent), cancelTimer, null));
    expect(sent, isEmpty);
    expect('${faults.single.exception}', contains('no longer in the session data'));
  });

  test('the recorded controls are the ones this app sends, in the skill namespace', () {
    final sent = [
      for (final line in File('test/fixtures/outgoing/alerts_controls_round_trip.jsonl').readAsLinesSync())
        jsonDecode(line)['sent'] as Json,
    ];
    expect([for (final m in sent) m['event_name']], [cancelTimer, snoozeAlarm, cancelAlarm]);
    expect(sent.every((m) => m['namespace'] == alerts), isTrue);
    expect((sent[1]['parameters'] as Json).keys, ['alarmIndex', 'alarmContext', 'alarmName']);
    expect(sent[1]['parameters']['alarmContext'], overviewContext);
  });
}
