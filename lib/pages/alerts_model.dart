/// View models for ovos-skill-alerts pages (SPEC 8.5), from session data exactly as the skill sends it
/// (ovos_skill_alerts/util/ui_models.py build_timer_data / build_alarm_data, __init__.py _display_list). Pure.
library;

import 'dart:math' as math;

import '../json.dart';
import 'page.dart';

/// Four rings plus gaps must fit above the compact-face strip: 4 * 140 + 3 * 22 = 626 <= 800 - 32 - 118.
const timerSizes = [300.0, 230.0, 180.0, 140.0];

/// alerts 0.12.36a2 sends percentRemaining ~0.99999 for the whole timer, so a value this close to 1 is treated as
/// missing and progress comes from timeDelta instead.
const stuckPercent = 0.999;
const warmBelow = 0.3;
const hotBelow = 0.1;
final _delta = RegExp(r'^-?(?:(\d+)d\s+)?(\d+(?::\d{1,2}){0,2})$');

double _clamp01(Object? value) => number(value).clamp(0, 1).toDouble();

/// Seconds in a nice_duration(speech=False) string: "0:45", "1:42", "1:02:05", "1d 0:00:05"; sign ignored.
int? parseDelta(Object? value) {
  final match = _delta.firstMatch(text(value).trim());
  if (match == null) return null;
  final parts = match.group(2)!.split(':').map(int.parse).toList();
  final padded = [0, 0, 0, ...parts];
  final h = padded[padded.length - 3], m = padded[padded.length - 2], s = padded[padded.length - 1];
  return int.parse(match.group(1) ?? '0') * 86400 + h * 3600 + m * 60 + s;
}

/// Remaining fraction. [longest] maps alertId to the largest remaining time seen; it is updated here.
double timerFraction(Map timer, Map<String, int> longest) {
  if (truthy(timer['expired'])) return 1;
  final percent = timer['percentRemaining'];
  final percentValue = percent is num ? percent.toDouble() : double.tryParse(text(percent));
  if (percentValue != null && percentValue.isFinite && percentValue < stuckPercent) return _clamp01(percentValue);
  final seconds = parseDelta(timer['timeDelta']);
  if (seconds == null) return _clamp01(percentValue);
  final id = text(timer['alertId']);
  final total = math.max(longest[id] ?? 0, seconds);
  longest[id] = total;
  return total > 0 ? seconds / total : 0;
}

enum TimerTone { calm, warm, hot, done }

TimerTone timerTone(double fraction, bool expired) {
  if (expired) return TimerTone.done;
  if (fraction <= hotBelow) return TimerTone.hot;
  return fraction <= warmBelow ? TimerTone.warm : TimerTone.calm;
}

typedef TimerView = ({String id, String name, String delta, double fraction, bool expired, TimerTone tone});

({double size, List<TimerView> timers}) timerModel(Json? data, Map<String, int> longest) {
  final active = data?['activeTimers'];
  final raw = active is Map ? active['timers'] : null;
  final timers = raw is List ? raw.whereType<Map>().toList() : const <Map>[];
  final size = timers.isEmpty ? timerSizes[0] : timerSizes[math.min(timers.length, timerSizes.length) - 1];
  return (size: size, timers: [for (final timer in timers) _timerView(timer, longest)]);
}

TimerView _timerView(Map timer, Map<String, int> longest) {
  final expired = truthy(timer['expired']);
  final fraction = timerFraction(timer, longest);
  final delta = text(timer['timeDelta']);
  return (
    id: text(timer['alertId']),
    name: text(timer['timerName']).isEmpty ? 'Timer' : text(timer['timerName']),
    delta: expired ? delta.replaceFirst(RegExp(r'^-'), '+') : delta,
    fraction: fraction,
    expired: expired,
    tone: timerTone(fraction, expired),
  );
}

typedef AlarmView = ({String id, String time, String ampm, String name, String repeat, bool expired});

List<AlarmView> alarmsModel(Json? data) {
  final raw = data?['activeAlarms'];
  final alarms = raw is List ? raw.whereType<Map>() : const <Map>[];
  return [
    for (final alarm in alarms)
      (
        id: text(alarm['alarmIndex']),
        time: text(alarm['alarmTime']),
        ampm: text(alarm['alarmAmPm']),
        name: text(alarm['alarmName']).isEmpty ? 'Alarm' : text(alarm['alarmName']),
        repeat: text(alarm['alarmRepeatStr']),
        expired: truthy(alarm['alarmExpired']),
      ),
  ];
}

/// The alarm that gets the quiet "next" glow: the first pending one (the skill sorts by next expiration). None
/// while any alarm is ringing (expired = going off now).
String? nextToFire(List<AlarmView> alarms) {
  if (alarms.any((alarm) => alarm.expired)) return null;
  return alarms.isEmpty ? null : alarms.first.id;
}

/// The alarm circles that fit the grid: all of them up to [max], else max - 1 plus a "+n more" count.
({List<AlarmView> shown, int more, String? next}) alarmGrid(List<AlarmView> alarms, {int max = 4}) {
  final next = nextToFire(alarms);
  if (alarms.length <= max) return (shown: alarms, more: 0, next: next);
  return (shown: alarms.sublist(0, max - 1), more: alarms.length - (max - 1), next: next);
}

typedef ListItem = ({String main, String secondary});

({String header, List<ListItem> items}) listModel(Json? data) {
  final raw = data?['items'];
  final items = raw is List ? raw : const [];
  return (
    header: text(data?['header']),
    items: [
      for (final item in items)
        item is Map ? (main: text(item['main']), secondary: text(item['secondary'])) : (main: text(item), secondary: ''),
    ],
  );
}
