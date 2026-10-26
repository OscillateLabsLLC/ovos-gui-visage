/// ovos-skill-homescreen.openvoiceos / idle (SPEC 8.1): weather circle, clock circle, widget chips and the
/// notification badge, from the homescreen's session data and its widget-manager events; the badge counts and opens
/// the shell's stored notification list.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/home_chips.dart';
import 'page.dart';

export '../widgets/home_chips.dart' show showNotificationsLabel;

const timerEvent = 'ovos.timer.widget.manager.update';
const alarmEvent = 'ovos.alarm.widget.manager.update';
const mediaEvent = 'ovos.media.widget.manager.update';

/// ovos-skill-homescreen's weather_code switch.
const homescreenWeatherIcons = ['sun', 'partial_clouds', 'clouds', 'rain', 'rain', 'storm', 'snow', 'fog'];

String weatherIconName(Object? code) {
  final index = number(code, -1).toInt();
  return index >= 0 && index < homescreenWeatherIcons.length ? homescreenWeatherIcons[index] : 'clouds';
}

String dateLine(Json data) {
  final day = text(data['day_string']);
  final month = text(data['month_string']);
  final dayMonth = (data['dateFormat'] == 'MDY' ? '$month $day' : '$day $month').trim();
  final parts = [text(data['weekday_string']), dayMonth].where((s) => s.isNotEmpty);
  return parts.isEmpty ? text(data['date_string']) : parts.join(', ');
}

bool hasWeather(Json data) => truthy(data['weather_api_enabled']) && data['weather_temp'] != null;

/// The badge counts the stored list it opens, as WidgetsArea.qml shows `notificationModel.count`; the session's
/// `notifcation_counter` (sic) only ever grows, so it is not shown.
class IdlePage extends StatelessWidget {
  const IdlePage({
    super.key,
    required this.data,
    required this.events,
    required this.storedNotifications,
    required this.onShowNotifications,
  });

  static Widget page(Json data, PageContext ctx) => IdlePage(
    data: data,
    events: ctx.events,
    storedNotifications: ctx.storedNotifications,
    onShowNotifications: ctx.showNotifications,
  );

  final Json data;
  final Json events;
  final int storedNotifications;
  final VoidCallback onShowNotifications;

  @override
  Widget build(BuildContext context) {
    final timer = events[timerEvent] as Map?;
    final alarm = events[alarmEvent] as Map?;
    final media = events[mediaEvent] as Map?;
    return WithCountBadge(
      count: storedNotifications,
      onTap: onShowNotifications,
      child: StaggerEnter(
        mainAxisSize: MainAxisSize.max,
        children: [
          if (hasWeather(data))
            WeatherChip(icon: weatherIconName(data['weather_code']), temperature: '${number(data['weather_temp']).round()}°'),
          ClockChip(time: text(data['time_string']), date: dateLine(data)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 18,
            children: [
              if (number(timer?['count']) > 0) _countChip(number(timer?['count']).toInt(), 'timer'),
              if (number(alarm?['count']) > 0) _countChip(number(alarm?['count']).toInt(), 'alarm'),
              if (media?['state'] == 'playing') _mediaChip(media?['widget'] as Map? ?? const {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip(int count, String noun) {
    return Circle(
      size: 120,
      fill: VisageColors.card,
      ring: const Ring(),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: VisageText.fg(34, height: 1)),
            const SizedBox(height: 6),
            Text(count == 1 ? noun : '${noun}s', style: VisageText.muted(13)),
          ],
        ),
      ],
    );
  }

  Widget _mediaChip(Map widget) {
    return Circle(
      size: 120,
      fill: VisageColors.card,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('♪', style: VisageText.fg(34, height: 1)),
              const SizedBox(height: 6),
              Text(text(widget['title']), maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(13)),
              Text(text(widget['artist']), maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(13)),
            ],
          ),
        ),
      ],
    );
  }
}
