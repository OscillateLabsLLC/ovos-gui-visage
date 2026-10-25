/// SYSTEM_weather ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue)):
/// the skill's current-weather card with the forecast's first entries beneath it (weather_card_model.dart). A
/// producer `icon` that fails to load is reported and the `condition_code` icon shows instead.
library;

import 'package:flutter/widgets.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../widgets/weather_icon.dart';
import 'data_faults.dart';
import 'forecast_page.dart';
import 'page.dart';
import 'spec_weather.dart';
import 'weather_card_model.dart';
import 'weather_now_page.dart';

const _iconSize = 120.0;

class SystemWeatherPage extends StatelessWidget {
  const SystemWeatherPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => SystemWeatherPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final weather = specWeather(data);
    final card = weatherCard(weather, use24Hour: MediaQuery.alwaysUse24HourFormatOf(context));
    final fallback = card.now.icon.isEmpty ? const SizedBox.shrink() : WeatherIcon(card.now.icon, size: _iconSize);
    return ReportsDataFaults(
      template: 'SYSTEM_weather',
      problems: weather.problems,
      child: WeatherNowCard(
        model: card.now,
        icon: imageFor(card.image, broken: fallback),
        footer: card.forecast.isEmpty
            ? null
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 8,
                children: [for (final item in card.forecast) ForecastCircle(item: item)],
              ),
      ),
    );
  }
}
