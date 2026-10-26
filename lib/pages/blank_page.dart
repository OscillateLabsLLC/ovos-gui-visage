/// Built-in idle when no namespace has a page (SPEC 7.1): a logo badge and the local clock.
library;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/device_clock.dart';

export '../widgets/device_clock.dart' show clockLine, dateLine;

class BlankPage extends StatelessWidget {
  const BlankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaggerEnter(
      mainAxisSize: MainAxisSize.max,
      children: [
        Circle(
          size: 120,
          gradient: gradientFill,
          glow: Glow(bloom: true),
          ring: Ring(),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: VisageColors.accent),
              child: SizedBox(width: 36, height: 36),
            ),
          ],
        ),
        DeviceClock(),
      ],
    );
  }
}
