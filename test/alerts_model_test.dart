// Port of tests/js/alerts_model.test.mjs.
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/alerts_model.dart';

void main() {
  test('parseDelta reads every nice_duration(speech=False) shape', () {
    const cases = {
      '0:05': 5, '0:45': 45, '1:00': 60, '1:42': 102, '10:00': 600, '59:59': 3599,
      '1:00:00': 3600, '1:02:05': 3725, '1d 0:00:05': 86405, '-3:49': 229,
    };
    cases.forEach((value, seconds) => expect(parseDelta(value), seconds, reason: value));
    expect(parseDelta('soon'), isNull);
    expect(parseDelta(null), isNull);
  });

  test('stuck percentRemaining falls back to timeDelta over the longest delta seen', () {
    final longest = <String, int>{};
    double tick(String delta) => timerFraction({'alertId': 'a', 'percentRemaining': 0.99999, 'timeDelta': delta, 'expired': false}, longest);
    expect(tick('2:00'), 1);
    expect(tick('1:30'), 0.75);
    expect(tick('0:00'), 0);
  });

  test('a real percentRemaining is trusted, expired is a full ring', () {
    expect(timerFraction({'alertId': 'a', 'percentRemaining': 0.4, 'timeDelta': '0:10'}, {}), 0.4);
    expect(timerFraction({'alertId': 'a', 'percentRemaining': 0, 'timeDelta': '-0:05', 'expired': true}, {}), 1);
    expect(timerFraction({'alertId': 'a', 'percentRemaining': 'x', 'timeDelta': 'later'}, {}), 0);
  });

  test('timer model sizes the stack and marks overrun', () {
    Map timer(String id, bool expired) =>
        {'alertId': id, 'timerName': '', 'timeDelta': expired ? '-0:07' : '2:15', 'percentRemaining': 0.99999, 'expired': expired};
    final one = timerModel({'activeTimers': {'timers': [timer('a', false)]}}, {});
    final two = timerModel({'activeTimers': {'timers': [timer('a', true), timer('b', false)]}}, {});
    expect(one.size, 300);
    expect(two.size, 230);
    expect(two.timers[0], (id: 'a', name: 'Timer', delta: '+0:07', fraction: 1.0, expired: true, tone: TimerTone.done));
    expect(timerModel({}, {}).timers, isEmpty);
  });

  test('alarms model keeps time, am/pm, name, repeat and expiry', () {
    final alarms = alarmsModel({
      'activeAlarms': [
        {'alarmIndex': 'x', 'alarmTime': '7:00', 'alarmAmPm': 'AM', 'alarmName': '', 'alarmRepeatStr': 'Weekdays', 'alarmExpired': true},
      ],
    });
    expect(alarms.single, (id: 'x', time: '7:00', ampm: 'AM', name: 'Alarm', repeat: 'Weekdays', expired: true));
    expect(alarmsModel({'activeAlarms': null}), isEmpty);
  });

  test("list model uses the skill's {main, secondary} items", () {
    final model = listModel({
      'header': 'Reminders',
      'items': [{'main': 'stretch', 'secondary': '11:00 PM'}, {'main': 'water'}, 'plain'],
    });
    expect(model.header, 'Reminders');
    expect(model.items, [(main: 'stretch', secondary: '11:00 PM'), (main: 'water', secondary: ''), (main: 'plain', secondary: '')]);
    expect(listModel({}).items, isEmpty);
  });

  test('the ring warms over the final stretch and is done when expired', () {
    expect([1.0, 0.31, 0.3, 0.11, 0.1, 0.0].map((f) => timerTone(f, false)),
        [TimerTone.calm, TimerTone.calm, TimerTone.warm, TimerTone.warm, TimerTone.hot, TimerTone.hot]);
    expect(timerTone(0.9, true), TimerTone.done);
    final longest = {'a': 100};
    final tones = ['1:40', '0:25', '0:05'].map((delta) => timerModel({
          'activeTimers': {'timers': [{'alertId': 'a', 'timeDelta': delta, 'percentRemaining': 0.99999}]},
        }, longest).timers[0].tone);
    expect(tones, [TimerTone.calm, TimerTone.warm, TimerTone.hot]);
  });

  test('the alarm grid shows up to four circles, else three and a +n more, and marks the next to fire', () {
    List<AlarmView> alarms(int n) =>
        [for (var i = 0; i < n; i++) (id: '$i', time: '', ampm: '', name: '', repeat: '', expired: false)];
    expect([3, 4].map((n) => alarmGrid(alarms(n)).more), [0, 0]);
    expect(alarmGrid(alarms(4)).shown.length, 4);
    final six = alarmGrid(alarms(6));
    expect((six.shown.length, six.more, six.next), (3, 3, '0'));
  });

  test('the next to fire is the first pending alarm, and nothing is next while one is ringing', () {
    AlarmView alarm(String id, bool expired) => (id: id, time: '', ampm: '', name: '', repeat: '', expired: expired);
    expect(nextToFire([alarm('a', false), alarm('b', false)]), 'a');
    expect(nextToFire([alarm('a', false), alarm('b', true)]), isNull);
    expect(alarmGrid([alarm('a', true), alarm('b', false), alarm('c', false)]).next, isNull);
    expect(nextToFire([]), isNull);
  });
}
