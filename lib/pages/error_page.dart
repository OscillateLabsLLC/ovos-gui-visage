/// SYSTEM_error (gui-1.md §3.4, line 220): a chip-sized gradient circle with an exclamation mark in the failure red,
/// a red-tinted glow that blooms once as the error arrives and then breathes, the label beneath and the detail muted
/// under it. With reduced motion the halo stands still.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'content_models.dart';
import 'loading_page.dart' show lottieChipPx;
import 'page.dart';
import 'reduced_motion.dart';
import 'template_text.dart';

const errorMark = '!';
const _badSoft = Color(0x2EFF5C5C);
const _badDim = Color(0x66FF5C5C);
const _bloom = Duration(milliseconds: 900);

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => ErrorPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:label, :detail) = errorModel(data);
    return StaggerOrStill(
      children: [
        Circle(
          size: lottieChipPx,
          gradient: gradientFill,
          glow: const ErrorGlow(),
          ring: const Ring(track: _badDim, value: VisageColors.bad),
          children: [
            Text(
              errorMark,
              style: VisageText.fg(96, weight: FontWeight.w300).copyWith(color: VisageColors.bad),
            ),
          ],
        ),
        TemplateLabel(label),
        if (detail.isNotEmpty) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: TemplateHint(detail)),
      ],
    );
  }
}

/// The red hero glow: a bloom (the halo swells once and settles) over the breathing [Glow]. The bloom scales the
/// shadow's alpha rather than an Opacity, since an Opacity over a blur-only box breaks on Impeller.
class ErrorGlow extends StatelessWidget {
  const ErrorGlow({super.key});

  @override
  Widget build(BuildContext context) {
    if (reducedMotion(context)) return halo(alpha: 1, swell: 0);
    return Stack(
      fit: StackFit.expand,
      children: [
        const Glow(colour: _badSoft),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: _bloom,
          builder: (context, t, _) {
            final swell = math.sin(math.pi * t);
            return halo(alpha: swell, swell: swell);
          },
        ),
      ],
    );
  }

  /// The red halo at [alpha] times its resting alpha, at rest ([swell] 0) or swollen ([swell] 1). The bloom fades to
  /// alpha 0, so the breathing glow alone remains; the still frame is the resting halo.
  static Widget halo({required double alpha, required double swell}) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: _badSoft.withValues(alpha: _badSoft.a * alpha),
          blurRadius: 34 + 30 * swell,
          spreadRadius: 2 + 12 * swell,
        ),
      ],
    ),
  );
}
