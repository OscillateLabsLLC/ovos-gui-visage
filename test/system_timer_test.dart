import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/alerts_model.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/system_timer_model.dart';
import 'package:ovos_gui_visage/pages/system_timer_page.dart';
import 'package:ovos_gui_visage/pages/timer_page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const endTime = 1792929600;

DateTime secondsBefore(int seconds) => DateTime.fromMillisecondsSinceEpoch((endTime - seconds) * 1000);

TimerSpec spec({bool countUp = false, String label = ''}) =>
    (endTime: endTime.toDouble(), label: label, countUp: countUp, problems: const []);

void main() {
  group('model', () {
    test('reads the three keys and reports none when they are right', () {
      final read = timerSpec({'end_time': endTime, 'label': 'Pasta', 'count_up': true});
      expect([read.endTime, read.label, read.countUp, read.problems], [endTime.toDouble(), 'Pasta', true, isEmpty]);
      expect(timerSpec({'end_time': 1.5}).problems, isEmpty);
    });

    test('a missing or mistyped key is a problem; the rest still reads', () {
      expect(timerSpec({}).problems, ['end_time is required']);
      expect(timerSpec({}).endTime, isNull);
      final bad = timerSpec({'end_time': '1792929600', 'label': 7, 'count_up': 'yes'});
      expect(bad.problems, hasLength(3));
      expect(bad.problems.first, 'end_time must be a finite number, got String 1792929600');
      expect([bad.endTime, bad.label, bad.countUp], [null, '', false]);
    });

    test('durations in the alerts skill form', () {
      expect([clockDuration(0), clockDuration(45), clockDuration(723)], ['0:00', '0:45', '12:03']);
      expect([clockDuration(3725), clockDuration(2 * 86400 + 3 * 3600)], ['1:02:05', '2d 3:00:00']);
    });

    test('counting down: remaining time rounds up, progress against the longest seen', () {
      final longest = <String, int>{};
      final first = timerAt(spec(label: 'Pasta'), secondsBefore(600), longest);
      expect(
        [first.name, first.delta, first.fraction, first.expired, first.tone],
        ['Pasta', '10:00', 1.0, false, TimerTone.calm],
      );
      final later = timerAt(spec(), DateTime.fromMillisecondsSinceEpoch((endTime - 30) * 1000 - 400), longest);
      expect([later.name, later.delta, later.fraction, later.tone], ['Timer', '0:31', 31 / 600, TimerTone.hot]);
    });

    test('a past end_time counting down shows the expired state with the time since', () {
      final done = timerAt(spec(), secondsBefore(-12), {});
      expect([done.delta, done.expired, done.tone, done.fraction], ['+0:12', true, TimerTone.done, 1.0]);
      expect(timerAt(spec(), secondsBefore(0), {}).expired, isTrue);
    });

    test('counting up holds at 0:00 before end_time, then counts the time since it', () {
      expect(timerAt(spec(countUp: true), secondsBefore(5), {}).delta, '0:00');
      final up = timerAt(spec(countUp: true), secondsBefore(-75), {});
      expect([up.delta, up.expired, up.fraction], ['1:15', false, 1.0]);
    });

    test('without an end_time the label shows over dashes', () {
      final view = timerAt((endTime: null, label: 'Tea', countUp: false, problems: const ['x']), secondsBefore(1), {});
      expect([view.name, view.delta, view.expired], ['Tea', noTime, false]);
    });
  });

  testWidgets('system_timer fixture: the ring counts down from the device clock, then expires', (tester) async {
    final state = replayGui1(loadGui1Fixture('system_timer'));
    expect(state.current(), const Target(alerts, 'SYSTEM_timer', 0));
    expect(resolve(state.current(), gaps: TemplateGaps()), same(SystemTimerPage.page));
    var now = secondsBefore(62);
    await tester.pumpWidget(host(SystemTimerPage(data: state.namespace(alerts).data, now: () => now)));
    expect([find.text('1:02'), find.text('Pasta')], everyElement(findsOneWidget));
    now = secondsBefore(61);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1:01'), findsOneWidget);
    now = secondsBefore(-3);
    await tester.pump(const Duration(seconds: 1));
    expect([find.text(finished), find.text('+0:03')], everyElement(findsOneWidget));
  });

  testWidgets('the routed page renders the ring with the real clock', (tester) async {
    final state = replayGui1(loadGui1Fixture('system_timer'));
    await tester.pumpWidget(host(pageOf(state)));
    expect(find.byType(TimerRing), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
  });

  testWidgets('a missing end_time is reported once and the label still shows', (tester) async {
    final state = replayGui1([
      template(alerts, 'SYSTEM_timer', {'label': 'Tea'}),
    ]);
    final faults = await collectFaults(() async {
      await tester.pumpWidget(host(pageOf(state)));
      await tester.pump(const Duration(seconds: 3));
    });
    expect(faults.map((f) => '${f.exception}'), ['FormatException: end_time is required']);
    expect(faults.single.context?.toDescription(), 'SYSTEM_timer data');
    expect([find.text('Tea'), find.text(noTime)], everyElement(findsOneWidget));
  });
}
