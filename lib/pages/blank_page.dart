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
        const DeviceClock(),
      ],
    );
  }
}
