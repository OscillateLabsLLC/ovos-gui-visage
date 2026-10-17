/// ovos-skill-date-time / date: a circle with weekday, day-month and year (SPEC 8.4).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';

const _pythonNone = 'None';

/// The date-time skill sends `location_string` as the string "None" when no location is set.
String locationLine(Object? value) {
  final line = text(value);
  return line == _pythonNone ? '' : line;
}

String capitalize(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

class DatePage extends StatelessWidget {
  const DatePage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => DatePage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final dayMonth = text(data['daymonth_string'] ?? data['date_string']);
    final location = locationLine(data['location_string']);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Circle(
          size: 330,
          gradient: const RadialGradient(colors: [VisageColors.clockTop, VisageColors.clockBottom], stops: [0, 0.7]),
          glow: const Glow(),
          ring: const Ring(),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  capitalize(text(data['weekday_string'])),
                  style: VisageText.base.copyWith(color: VisageColors.accent, fontSize: 26),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: Text(
                      capitalize(dayMonth),
                      textAlign: TextAlign.center,
                      style: VisageText.fg(54, weight: FontWeight.w300, height: 1.1),
                    ),
                  ),
                ),
                Text(text(data['year_string']), style: VisageText.muted(26).copyWith(fontFeatures: VisageText.tabular)),
              ],
            ),
          ],
        ),
        if (location.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(location, textAlign: TextAlign.center, style: VisageText.muted(16)),
        ],
      ],
    );
  }
}
