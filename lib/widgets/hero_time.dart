/// The time inside a clock circle, sized so a five-glyph time (`10:27`) never meets the ring. A line of text sits on
/// the circle's horizontal diameter, and at its own height the chord is shorter than the diameter, so the usable
/// width is [heroTimeWidthFraction] of the circle; a time wider than that scales down, a narrower one keeps its size.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Of the circle's size: the ring's inner edge is at 0.86, and the chord at half a 92 px cap height is about 0.83;
/// 0.76 leaves a visible gap to the ring on both sides.
const heroTimeWidthFraction = 0.76;

class HeroTime extends StatelessWidget {
  const HeroTime({super.key, required this.time, required this.circleSize, required this.fontSize});

  final String time;
  final double circleSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: circleSize * heroTimeWidthFraction,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          time.isEmpty ? '--:--' : time,
          style: VisageText.fg(
            fontSize,
            weight: FontWeight.w300,
            height: 1,
          ).copyWith(letterSpacing: -2, fontFeatures: VisageText.tabular),
        ),
      ),
    );
  }
}
