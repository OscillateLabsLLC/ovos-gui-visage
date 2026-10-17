/// ovos-skill-weather DailyForecast and HourlyForecast: a vertical column of small weather circles (SPEC 8.3).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/weather_icon.dart';
import 'page.dart';
import 'skill_header.dart';
import 'weather_model.dart';

class ForecastPage extends StatelessWidget {
  const ForecastPage({super.key, required this.data, required this.page});

  static Widget build_(Json data, PageContext ctx) => ForecastPage(data: data, page: ctx.page);

  final Json data;
  final String page;

  @override
  Widget build(BuildContext context) {
    final model = forecastModel(page, data);
    final subColour = model.hourly ? VisageColors.accent : VisageColors.muted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 20), child: SkillHeader(heading: model.heading, location: model.location)),
        for (final item in model.items) _item(item, subColour),
      ],
    );
  }

  Widget _item(ForecastItem item, Color subColour) {
    return Circle(
      size: 108,
      fill: VisageColors.card,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.label, style: VisageText.muted(13)),
            WeatherIcon(item.icon, size: 40),
            // Scales down rather than overflowing the circle with a wide font or a three-digit temperature.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 8,
                children: [
                  Text(item.main, style: VisageText.fg(22).copyWith(fontFeatures: VisageText.tabular)),
                  Text(item.sub, style: VisageText.base.copyWith(color: subColour, fontSize: 14, fontFeatures: VisageText.tabular)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
