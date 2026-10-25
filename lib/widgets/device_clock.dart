/// The device's own clock in the concept's blue circle, ticking each second: the built-in blank page and the GUI-1
/// resting display both show it, since neither has a producer for the time (gui-1.md §6.9.1).
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'circle.dart';

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String clockLine(DateTime now) => '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

String dateLine(DateTime now) => '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';

/// [now] is the clock it reads, so a test can fix the time.
class DeviceClock extends StatefulWidget {
  const DeviceClock({super.key, this.now = DateTime.now});

  final DateTime Function() now;

  @override
  State<DeviceClock> createState() => _DeviceClockState();
}

class _DeviceClockState extends State<DeviceClock> {
  late final Timer _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));

  @override
  void initState() {
    super.initState();
    _ticker;
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.now();
    return Circle(
      size: 300,
      gradient: const RadialGradient(colors: [VisageColors.clockTop, VisageColors.clockBottom], stops: [0, 0.7]),
      ring: const Ring(),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              clockLine(now),
              style: VisageText.fg(
                92,
                weight: FontWeight.w300,
                height: 1,
              ).copyWith(letterSpacing: -2, fontFeatures: VisageText.tabular),
            ),
            const SizedBox(height: 10),
            Text(dateLine(now), style: VisageText.muted(20)),
          ],
        ),
      ],
    );
  }
}
