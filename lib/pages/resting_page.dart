/// Visage's own resting display on the GUI-1 path (gui-1.md 6.9): the weather chip above the device clock, as the
/// homescreen stacks them, and the notification-count badge, all from the kept ambient data (gui-1.md 6.9.1). No
/// application owns it and nothing routes to it; the frame shows it when the stack is empty.
library;

import 'package:flutter/material.dart';

import '../protocol/wire_protocol.dart';
import '../state/gui_state.dart';
import '../widgets/device_clock.dart';
import '../widgets/home_chips.dart';
import 'resting_model.dart';

/// The resting page when [showsResting], else null and the routed page shows. The badge opens Visage's stored list.
Widget? restingPage(
  GuiState state,
  ChosenProtocol? protocol, {
  VoidCallback? onShowNotifications,
  DateTime Function() now = DateTime.now,
}) => showsResting(state, protocol)
    ? RestingPage(ambient: state.ambient, onShowNotifications: onShowNotifications ?? _noList, now: now)
    : null;

void _noList() {}

class RestingPage extends StatelessWidget {
  const RestingPage({super.key, required this.ambient, this.onShowNotifications = _noList, this.now = DateTime.now});

  final Map<String, Json> ambient;
  final VoidCallback onShowNotifications;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context) {
    final weather = restingWeather(ambient);
    return WithCountBadge(
      count: restingNotificationCount(ambient),
      onTap: onShowNotifications,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (weather != null) ...[
            WeatherChip(temperature: weather.temperature, icon: weather.icon, condition: weather.condition),
            const SizedBox(height: 28),
          ],
          DeviceClock(now: now),
        ],
      ),
    );
  }
}
