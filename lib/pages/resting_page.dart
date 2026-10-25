/// Visage's own resting display on the GUI-1 path (gui-1.md §6.9): the device clock and, once one has arrived, the
/// ambient weather. No application owns it and nothing routes to it; the frame shows it when the stack is empty.
library;

import 'package:flutter/material.dart';

import '../protocol/wire_protocol.dart';
import '../state/gui_state.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/device_clock.dart';
import '../widgets/weather_icon.dart';
import 'resting_model.dart';

/// The resting page when [showsResting], else null and the routed page shows.
Widget? restingPage(GuiState state, ChosenProtocol? protocol, {DateTime Function() now = DateTime.now}) =>
    showsResting(state, protocol) ? RestingPage(ambient: state.ambient, now: now) : null;

class RestingPage extends StatelessWidget {
  const RestingPage({super.key, required this.ambient, this.now = DateTime.now});

  final Map<String, Json> ambient;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final weather = restingWeather(ambient);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (weather != null) ...[_weather(weather), const SizedBox(height: 28)],
        DeviceClock(now: now),
      ],
    );
  }

  Widget _weather(RestingWeather weather) {
    return Circle(
      size: 170,
      fill: VisageColors.card,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (weather.icon case final icon?) WeatherIcon(icon, size: 64),
            Text(weather.temperature, style: VisageText.fg(34)),
            Text(weather.condition, maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(15)),
          ],
        ),
      ],
    );
  }
}
