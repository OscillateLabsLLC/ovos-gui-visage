/// ovos-skill-weather CurrentWeather and SingleDay: big weather circle with high, low and rain chips (SPEC 8.3).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/weather_icon.dart';
import 'page.dart';
import 'skill_header.dart';
import 'weather_model.dart';

class WeatherNowPage extends StatelessWidget {
  const WeatherNowPage({super.key, required this.data, required this.page});

  static Widget build_(Json data, PageContext ctx) => WeatherNowPage(data: data, page: ctx.page);

  final Json data;
  final String page;

  @override
  Widget build(BuildContext context) {
    final model = nowModel(page, data);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 28,
      children: [
        SkillHeader(heading: model.heading, location: model.location),
        Circle(
          size: 270,
          gradient: gradientFill,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                WeatherIcon(model.icon, size: 120),
                const SizedBox(height: 2),
                Text(model.big, style: VisageText.fg(76, weight: FontWeight.w300, height: 1).copyWith(fontFeatures: VisageText.tabular)),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 18,
          children: [for (final chip in model.chips) _chip(chip)],
        ),
        SkillDetails(model.details),
      ],
    );
  }

  Widget _chip(WeatherChip chip) {
    return Circle(
      size: 104,
      fill: VisageColors.card,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chip.value, style: VisageText.fg(34, height: 1).copyWith(fontFeatures: VisageText.tabular)),
            const SizedBox(height: 6),
            Text(chip.label, style: VisageText.muted(13)),
          ],
        ),
      ],
    );
  }
}
