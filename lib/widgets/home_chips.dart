/// The chips of a resting screen, as the Kickstarter stills stack them (ovos-visage SPEC 9): the weather circle above
/// the clock ring, and the notification-count badge at the top right. The homescreen skill's idle page and the GUI-1
/// resting page both build from these, so the two resting screens look the same.
library;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'circle.dart';
import 'weather_icon.dart';

const showNotificationsLabel = 'Show notifications';
const weatherChipSize = 170.0;
const clockChipSize = 300.0;

/// A weather icon above the temperature; without an icon, the condition text takes its place.
class WeatherChip extends StatelessWidget {
  const WeatherChip({super.key, required this.temperature, this.icon, this.condition = ''});

  final String temperature;
  final String? icon;
  final String condition;

  @override
  Widget build(BuildContext context) {
    return Circle(
      size: weatherChipSize,
      fill: VisageColors.card,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final name?)
              WeatherIcon(name, size: 72)
            else
              Text(condition, maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(17)),
            const SizedBox(height: 4),
            Text(temperature, style: VisageText.fg(34)),
          ],
        ),
      ],
    );
  }
}

/// The hero clock: the time large in a glowing blue ring, AM or PM beneath it on a 12-hour device, then the date.
class ClockChip extends StatelessWidget {
  const ClockChip({super.key, required this.time, required this.date, this.ampm = ''});

  final String time;
  final String date;
  final String ampm;

  @override
  Widget build(BuildContext context) {
    return Circle(
      size: clockChipSize,
      gradient: const RadialGradient(colors: [VisageColors.clockTop, VisageColors.clockBottom], stops: [0, 0.7]),
      glow: const Glow(),
      ring: const Ring(),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time.isEmpty ? '--:--' : time,
              style: VisageText.fg(
                92,
                weight: FontWeight.w300,
                height: 1,
              ).copyWith(letterSpacing: -2, fontFeatures: VisageText.tabular),
            ),
            if (ampm.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(ampm, style: VisageText.base.copyWith(color: VisageColors.accent, fontSize: 20, letterSpacing: 2)),
              ),
            const SizedBox(height: 10),
            Text(date, style: VisageText.muted(20)),
          ],
        ),
      ],
    );
  }
}

/// The pending-notification count; a tap opens the list.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: showNotificationsLabel,
      child: Material(
        color: VisageColors.accent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 28),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: Text('$count', style: VisageText.fg(15, weight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

/// [child] with the count badge in the shell's padding above its top right, when [count] is above zero.
class WithCountBadge extends StatelessWidget {
  const WithCountBadge({super.key, required this.count, required this.onTap, required this.child});

  final int count;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      // The badge sits in the shell's padding, above the page box; Stack would clip it by default. The chips are
      // narrower than the page, so without an alignment Stack would leave them at the left edge.
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -10,
            right: -2,
            child: CountBadge(count: count, onTap: onTap),
          ),
      ],
    );
  }
}
