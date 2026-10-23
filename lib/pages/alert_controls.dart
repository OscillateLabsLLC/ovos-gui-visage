/// Controls on ovos-skill-alerts' pages, sending what its QML sends with triggerGuiEvent in the skill's namespace (the
/// skill registers them with gui.register_handler, so the bus sees `<skill_id>.ovos.alerts.*`):
///
/// - TimerCard.qml's close button: `ovos.alerts.cancel_timer` with the whole timer as `timer` (the skill reads
///   `timer.alertId`).
/// - AlarmButtonView.qml: `ovos.alerts.snooze_alarm` (enabled only while the alarm rings) and
///   `ovos.alerts.cancel_alarm` (labelled Dismiss while it rings), each with `alarmIndex` (the alert id),
///   `alarmContext` ("overview" on AlarmsOverviewCard) and `alarmName`.
///
/// Pure lookups first (they read the raw session data, so the views stay as they are), then the buttons.
library;

import 'package:flutter/material.dart';

import '../faults.dart';
import '../json.dart';
import '../theme.dart';
import 'page.dart';

const cancelTimer = 'ovos.alerts.cancel_timer';
const snoozeAlarm = 'ovos.alerts.snooze_alarm';
const cancelAlarm = 'ovos.alerts.cancel_alarm';
const overviewContext = 'overview';

Iterable<Map> _maps(Object? list) => list is List ? list.whereType<Map>() : const [];

/// The timer as the skill sent it, or null when [alertId] is not on the page any more.
Json? cancelTimerParameters(Json? data, String alertId) {
  final active = data?['activeTimers'];
  final timers = _maps(active is Map ? active['timers'] : null);
  final timer = timers.where((t) => text(t['alertId']) == alertId).firstOrNull;
  return timer == null ? null : {'timer': timer};
}

/// What AlarmButtonView sends for the alarm [alarmIndex], or null when it is not on the page any more.
Json? alarmParameters(Json? data, String alarmIndex) {
  final alarm = _maps(data?['activeAlarms']).where((a) => text(a['alarmIndex']) == alarmIndex).firstOrNull;
  if (alarm == null) return null;
  return {'alarmIndex': alarm['alarmIndex'], 'alarmContext': overviewContext, 'alarmName': alarm['alarmName']};
}

/// Sends [event] with [parameters] when the item is still there; one that vanished between frames is reported.
void sendAlertEvent(PageContext ctx, String event, Json? parameters) {
  if (parameters != null) return ctx.trigger(event, parameters);
  reportFault('${ctx.namespace}/${ctx.page} sending $event', StateError('the item is no longer in the session data'));
}

/// A round close button over a timer ring's corner.
class TimerCancelButton extends StatelessWidget {
  const TimerCancelButton({super.key, required this.expired, required this.onPressed, this.size = 44});

  final bool expired;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: expired ? 'Dismiss timer' : 'Cancel timer',
    iconSize: size * 0.5,
    constraints: BoxConstraints.tight(Size.square(size)),
    style: IconButton.styleFrom(
      backgroundColor: expired ? VisageColors.bad : VisageColors.card,
      foregroundColor: VisageColors.fg,
    ),
    onPressed: onPressed,
    icon: const Icon(Icons.close_rounded),
  );
}

/// Snooze and Cancel (Dismiss while ringing) under an alarm.
class AlarmActions extends StatelessWidget {
  const AlarmActions({super.key, required this.ringing, required this.onSnooze, required this.onCancel});

  final bool ringing;
  final VoidCallback onSnooze;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 10,
    children: [
      if (ringing) _button('Snooze', onSnooze, VisageColors.accent),
      _button(ringing ? 'Dismiss' : 'Cancel', onCancel, ringing ? VisageColors.bad : VisageColors.card),
    ],
  );

  Widget _button(String label, VoidCallback onPressed, Color colour) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: colour,
      foregroundColor: VisageColors.fg,
      minimumSize: const Size(96, 40),
      textStyle: VisageText.fg(16, weight: FontWeight.w500),
    ),
    child: Text(label),
  );
}
