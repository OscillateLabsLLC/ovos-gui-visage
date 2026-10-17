/// ovos-skill-homescreen.openvoiceos / idle (SPEC 8.1): weather circle, clock circle, widget chips and the
/// notification badge, from the homescreen's session data and its widget-manager events.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';

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

int notificationCount(Json data) {
  final model = data['notification_model'];
  final stored = model is List ? model.length : number(model is Map ? model['count'] : 0).toInt();
  final counter = number(data['notifcation_counter']).toInt();
  return counter > stored ? counter : stored;
}

bool hasWeather(Json data) => truthy(data['weather_api_enabled']) && data['weather_temp'] != null;

class IdlePage extends StatelessWidget {
  const IdlePage({super.key, required this.data, required this.events});

  static Widget page(Json data, PageContext ctx) => IdlePage(data: data, events: ctx.events);

  final Json data;
  final Json events;

  @override
  Widget build(BuildContext context) {
    final count = notificationCount(data);
    final timer = events[timerEvent] as Map?;
    final alarm = events[alarmEvent] as Map?;
    final media = events[mediaEvent] as Map?;
    return Stack(
      // The badge sits in the shell's padding, above the page box; Stack would clip it by default.
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasWeather(data)) ...[_weather(), const SizedBox(height: 28)],
            _clock(),
            const SizedBox(height: 28),
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
        if (count > 0) Positioned(top: -10, right: -2, child: _badge(count)),
      ],
    );
  }

  Widget _weather() {
    return Circle(
      size: 170,
      fill: VisageColors.card,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon(weatherIconName(data['weather_code']), size: 72),
            const SizedBox(height: 4),
            Text('${number(data['weather_temp']).round()}°', style: VisageText.fg(34)),
          ],
        ),
      ],
    );
  }

  Widget _clock() {
    final time = text(data['time_string']);
    return Circle(
      size: 300,
      gradient: const RadialGradient(colors: [VisageColors.clockTop, VisageColors.clockBottom], stops: [0, 0.7]),
      glow: const Glow(),
      ring: const Ring(),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time.isEmpty ? '--:--' : time,
              style: VisageText.fg(92, weight: FontWeight.w300, height: 1).copyWith(letterSpacing: -2, fontFeatures: VisageText.tabular),
            ),
            const SizedBox(height: 10),
            Text(dateLine(data), style: VisageText.muted(20)),
          ],
        ),
      ],
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

  Widget _badge(int count) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: VisageColors.accent, borderRadius: BorderRadius.circular(14)),
      child: Text('$count', style: VisageText.fg(15, weight: FontWeight.w600)),
    );
  }
}
