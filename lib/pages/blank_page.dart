/// Built-in idle when no namespace has a page (SPEC 7.1): a logo badge and the local clock.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/circle.dart';

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

class BlankPage extends StatefulWidget {
  const BlankPage({super.key});

  @override
  State<BlankPage> createState() => _BlankPageState();
}

class _BlankPageState extends State<BlankPage> {
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
    final now = DateTime.now();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Circle(
          size: 120,
          ring: const Ring(),
          children: const [
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: VisageColors.accent),
              child: SizedBox(width: 36, height: 36),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Circle(
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
        ),
      ],
    );
  }
}
