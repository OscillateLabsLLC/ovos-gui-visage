/// The shared vocabulary of ovos-visage SPEC 9: circles, rings, the breathing glow, the gradient fill and the
/// stagger-enter motion. Pages compose these instead of inventing per-page effects.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

const ringStroke = 6.0;
const ringRadiusFraction = 0.46;

/// A filled circle with its children stacked and centred; [ring] draws a progress ring on its edge.
class Circle extends StatelessWidget {
  const Circle({
    super.key,
    required this.size,
    this.fill,
    this.gradient,
    this.ring,
    this.glow,
    this.children = const [],
  });

  final double size;
  final Color? fill;
  final Gradient? gradient;
  final Ring? ring;
  final Glow? glow;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (glow != null) Positioned.fill(child: glow!),
          Positioned.fill(
            child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: fill, gradient: gradient)),
          ),
          if (ring != null) Positioned.fill(child: ring!),
          ...children,
        ],
      ),
    );
  }
}

/// The lit-from-above radial fill of a hero circle (visage.css .gradient-fill).
const gradientFill = RadialGradient(
  center: Alignment(0, -0.3),
  radius: 0.7,
  colors: [VisageColors.gradientTop, VisageColors.card],
);

/// A track and a value arc from twelve o'clock, as widgets.js ring(): r 46 in a 100 box, stroke 6 (SPEC 9).
class Ring extends StatelessWidget {
  const Ring({super.key, this.fraction = 1, this.track = VisageColors.accentDim, this.value = VisageColors.accent, this.stroke = ringStroke});

  final double fraction;
  final Color track;
  final Color value;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction.clamp(0, 1).toDouble()),
      duration: const Duration(milliseconds: 900),
      builder: (context, animated, _) => CustomPaint(painter: _RingPainter(animated, track, value, stroke)),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.track, this.value, this.stroke);

  final double fraction;
  final Color track;
  final Color value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = size.shortestSide * ringRadiusFraction;
    final scale = size.shortestSide / 100;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * scale
      ..color = track;
    canvas.drawCircle(centre, radius, paint);
    if (fraction <= 0) return;
    paint
      ..color = value
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: centre, radius: radius), -math.pi / 2, 2 * math.pi * fraction, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.value != value || old.stroke != stroke;
}

/// The breathing halo behind a hero ring (visage.css .hero-glow); [colour] tints it, [loop] keeps it swelling.
class Glow extends StatefulWidget {
  const Glow({super.key, this.colour = VisageColors.accentSoft, this.loop = false});

  final Color colour;
  final bool loop;

  @override
  State<Glow> createState() => _GlowState();
}

class _GlowState extends State<Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.loop ? const Duration(milliseconds: 1100) : const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        final blur = widget.loop ? 34 + 30 * t : 34.0;
        final spread = widget.loop ? 2 + 12 * t : 2.0;
        return Opacity(
          opacity: widget.loop ? 1 : 0.45 + 0.55 * t,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: widget.colour, blurRadius: blur, spreadRadius: spread)],
            ),
          ),
        );
      },
    );
  }
}

/// Children fade and rise in, 260 ms each, 60 ms apart (visage.css .stagger-enter).
class StaggerEnter extends StatelessWidget {
  const StaggerEnter({super.key, required this.children, this.gap = 28, this.mainAxisSize = MainAxisSize.min});

  final List<Widget> children;
  final double gap;
  final MainAxisSize mainAxisSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          _Enter(delay: Duration(milliseconds: 60 * math.min(i, 5)), child: children[i]),
        ],
      ],
    );
  }
}

class _Enter extends StatelessWidget {
  const _Enter({required this.delay, required this.child});

  final Duration delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260) + delay,
      curve: Interval(delay.inMilliseconds / (260 + delay.inMilliseconds), 1, curve: Curves.easeOut),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: Transform.scale(scale: 0.97 + 0.03 * t, child: child)),
      ),
      child: child,
    );
  }
}
