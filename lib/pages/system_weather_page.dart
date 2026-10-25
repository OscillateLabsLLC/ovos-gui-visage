/// SYSTEM_weather (gui-1.md §3.4): the skill's current-weather card, with the producer's `icon` in place of the bundled
/// one when it sends a loadable image (an image that fails to load is reported and the bundled icon shows instead).
library;

import 'package:flutter/widgets.dart';

import '../json.dart';
import '../resources/resources.dart';
import '../widgets/weather_icon.dart';
import 'data_faults.dart';
import 'page.dart';
import 'weather_card_model.dart';
import 'weather_now_page.dart';

const _iconSize = 120.0;

class SystemWeatherPage extends StatelessWidget {
  const SystemWeatherPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => SystemWeatherPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final card = weatherCard(data);
    final bundled = WeatherIcon(card.now.icon, size: _iconSize);
    return ReportsDataFaults(
      template: 'SYSTEM_weather',
      problems: card.problems,
      child: WeatherNowCard(
        model: card.now,
        icon: imageFor(card.image, broken: bundled),
      ),
    );
  }
}
