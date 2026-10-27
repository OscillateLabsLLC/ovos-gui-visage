/// Visage's own resting display on the GUI-1 path (gui-1.md 6.9): the weather chip above the device clock, as the
/// homescreen stacks them, and the notification-count badge, all from the kept ambient data (gui-1.md 6.9.1). No
/// application owns it and nothing routes to it; the frame shows it when the stack is empty.
library;

import 'package:flutter/material.dart';

import '../protocol/wire_protocol.dart';
import '../state/ambient.dart';
import '../state/gui_state.dart';
import '../widgets/device_clock.dart';
import '../widgets/home_chips.dart';
import 'every_second.dart';
import 'resting_model.dart';

/// The resting page when [showsResting], else null and the routed page shows. The badge opens Visage's stored list.
Widget? restingPage(
  GuiState state,
  ChosenProtocol? protocol, {
  VoidCallback? onShowNotifications,
  DateTime Function() now = DateTime.now,
}) => showsResting(state, protocol)
    ? RestingPage(
        ambient: state.ambient,
        ambientAt: state.ambientAt,
        onShowNotifications: onShowNotifications ?? _noList,
        now: now,
      )
    : null;

void _noList() {}

/// Ticks each second, like the clock inside it, so the weather chip leaves when its payload ages out and the night
/// icon arrives at the hour (`resting_model.dart`).
class RestingPage extends StatefulWidget {
  const RestingPage({
    super.key,
    required this.ambient,
    this.ambientAt = const {},
    this.onShowNotifications = _noList,
    this.now = DateTime.now,
  });

  final Map<String, Json> ambient;
  final Map<String, DateTime> ambientAt;
  final VoidCallback onShowNotifications;
  final DateTime Function() now;

  @override
  State<RestingPage> createState() => _RestingPageState();
}

class _RestingPageState extends State<RestingPage> with EverySecond {
  @override
  Widget build(BuildContext context) {
    final weather = restingWeather(widget.ambient, now: widget.now(), keptAt: widget.ambientAt[ambientWeather]);
    return WithCountBadge(
      count: restingNotificationCount(widget.ambient),
      onTap: widget.onShowNotifications,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (weather != null) ...[
            WeatherChip(temperature: weather.temperature, icon: weather.icon, condition: weather.condition),
            const SizedBox(height: 28),
          ],
          DeviceClock(now: widget.now),
        ],
      ),
    );
  }
}
