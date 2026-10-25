/// SYSTEM_timer ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue)):
/// `end_time` (Unix seconds, required), `label`, `count_up`. What the ring
/// shows is derived from the device clock, as the alerts skill's rings are drawn (alerts_model.dart). Pure, except that
/// [timerAt] records the longest remaining time it has seen, the only progress total the template offers.
library;

import 'dart:math' as math;

import '../json.dart';
import 'alerts_model.dart';
import 'data_faults.dart';

const noTime = '--:--';
const defaultTimerName = 'Timer';
const _secondsPerDay = 86400;

typedef TimerSpec = ({double? endTime, String label, bool countUp, List<String> problems});

TimerSpec timerSpec(Json data) {
  final end = data['end_time'], label = data['label'], countUp = data['count_up'];
  return (
    endTime: finite(end),
    label: optionalText(label),
    countUp: countUp == true,
    problems: [
      requiredNumber(end, 'end_time'),
      optionalString(label, 'label'),
      optionalBool(countUp, 'count_up'),
    ].nonNulls.toList(),
  );
}

String _two(int value) => value.toString().padLeft(2, '0');

/// `0:45`, `12:03`, `1:02:05`, `2d 3:00:00`: the alerts skill's nice_duration form.
String clockDuration(int seconds) {
  final days = seconds ~/ _secondsPerDay, rest = seconds % _secondsPerDay;
  final hours = rest ~/ 3600, minutes = rest % 3600 ~/ 60, secs = rest % 60;
  if (days > 0) return '${days}d $hours:${_two(minutes)}:${_two(secs)}';
  return hours > 0 ? '$hours:${_two(minutes)}:${_two(secs)}' : '$minutes:${_two(secs)}';
}

/// The ring at [now]. A countdown past `end_time` shows the alerts skill's expired state: "Time's up" with the time
/// since, `+0:12`. Counting up before `end_time` holds at `0:00`. Without a usable `end_time` the label shows over
/// [noTime]. [longest] maps an end time to the most seconds seen remaining; it is updated here.
TimerView timerAt(TimerSpec spec, DateTime now, Map<String, int> longest) {
  final name = spec.label.isEmpty ? defaultTimerName : spec.label;
  final end = spec.endTime;
  if (end == null) return (id: '', name: name, delta: noTime, fraction: 0, expired: false, tone: TimerTone.calm);
  final ahead = end - now.millisecondsSinceEpoch / 1000;
  final id = '$end';
  if (spec.countUp) {
    final elapsed = math.max(0, (-ahead).floor());
    return (id: id, name: name, delta: clockDuration(elapsed), fraction: 1, expired: false, tone: TimerTone.calm);
  }
  if (ahead <= 0) {
    return (id: id, name: name, delta: '+${clockDuration((-ahead).floor())}', fraction: 1, expired: true, tone: TimerTone.done);
  }
  return _countingDown(id, name, ahead.ceil(), longest);
}

TimerView _countingDown(String id, String name, int remaining, Map<String, int> longest) {
  final total = math.max(longest[id] ?? 0, remaining);
  longest[id] = total;
  final fraction = remaining / total;
  return (
    id: id,
    name: name,
    delta: clockDuration(remaining),
    fraction: fraction,
    expired: false,
    tone: timerTone(fraction, false),
  );
}
