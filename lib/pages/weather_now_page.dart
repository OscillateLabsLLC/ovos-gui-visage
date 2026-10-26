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
  Widget build(BuildContext context) => WeatherNowCard(model: nowModel(page, data));
}

/// The big weather circle with its chips; SYSTEM_weather draws the same card, with the producer's image as [icon] and
/// its forecast as [footer].
class WeatherNowCard extends StatelessWidget {
  const WeatherNowCard({super.key, required this.model, this.icon, this.footer});

  final NowModel model;

  /// Shown in place of the bundled icon that [NowModel.icon] names. With neither, the circle holds the number alone.
  final Widget? icon;

  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final glyph = icon ?? (model.icon.isEmpty ? null : WeatherIcon(model.icon, size: 120));
    return StaggerEnter(
      mainAxisSize: MainAxisSize.max,
      children: [
        SkillHeader(heading: model.heading, location: model.location),
        Circle(
          size: 270,
          gradient: gradientFill,
          glow: const Glow(bloom: true),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (glyph != null) ...[SizedBox.square(dimension: 120, child: glyph), const SizedBox(height: 2)],
                Text(
                  model.big,
                  style: VisageText.fg(76, weight: FontWeight.w300, height: 1).copyWith(fontFeatures: VisageText.tabular),
                ),
              ],
            ),
          ],
        ),
        Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 18, children: [for (final chip in model.chips) _chip(chip)]),
        if (model.details.isNotEmpty) SkillDetails(model.details),
        ?footer,
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
