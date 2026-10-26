/// The shared vocabulary of ovos-visage SPEC 9: circles, rings, the breathing glow, the gradient fill and the
/// stagger-enter motion (enter.dart). Pages compose these instead of inventing per-page effects.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

export 'enter.dart';

const ringStroke = 6.0;
const ringRadiusFraction = 0.46;

/// The glow's phase in its still frame: halfway through a breath.
const glowStillPhase = 0.5;

/// The platform asks for no motion (reduce motion, or a test that turns animations off); every animation here then
/// draws its still frame.
bool motionReduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// A filled circle with its children stacked and centred; [ring] draws a progress ring on its edge.
class Circle extends StatelessWidget {
  const Circle({super.key, required this.size, this.fill, this.gradient, this.ring, this.glow, this.children = const []});

  final double size;
  final Color? fill;
  final Gradient? gradient;

  /// Usually a [Ring]; any widget that fills the circle's box works (a pulsing wrapper around one, say).
  final Widget? ring;
  final Widget? glow;
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
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: fill, gradient: gradient),
            ),
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
  const Ring({
    super.key,
    this.fraction = 1,
    this.track = VisageColors.accentDim,
    this.value = VisageColors.accent,
    this.stroke = ringStroke,
  });

  final double fraction;
  final Color track;
  final Color value;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final target = fraction.clamp(0, 1).toDouble();
    if (motionReduced(context)) return CustomPaint(painter: _RingPainter(target, track, value, stroke));
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
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

/// The bloom's swell, and the loop's swell each way (docs/DESIGN.md, Motion language).
const glowSwell = Duration(milliseconds: 1100);
const _breath = Duration(seconds: 6);

/// The bloom: the halo swells once (ease-out) and settles back over the same time while the breath runs beneath it.
final _bloomSwell = TweenSequence<double>([
  TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
  TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
]);

/// The breathing halo behind a hero ring (visage.css .hero-glow); [colour] tints it, [loop] keeps it swelling, and
/// [bloom] swells it once when it first builds, as its state arrives.
class Glow extends StatefulWidget {
  const Glow({super.key, this.colour = VisageColors.accentSoft, this.loop = false, this.bloom = false});

  final Color colour;
  final bool loop;
  final bool bloom;

  @override
  State<Glow> createState() => _GlowState();
}

/// The halo scales its own alpha rather than sitting under an Opacity, which would push a layer for one gradient. Under
/// reduced motion both controllers stop and the halo holds [glowStillPhase] with no bloom.
class _GlowState extends State<Glow> with TickerProviderStateMixin {
  late final AnimationController _breathing = AnimationController(vsync: this, duration: widget.loop ? glowSwell : _breath);
  late final AnimationController _bloom = AnimationController(vsync: this, duration: glowSwell * 2, value: widget.bloom ? 0 : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionReduced(context)) {
      _breathing.stop();
      _bloom.value = 1;
      return;
    }
    if (!_breathing.isAnimating) _breathing.repeat(reverse: true);
    if (_bloom.value < 1 && !_bloom.isAnimating) _bloom.forward();
  }

  @override
  void dispose() {
    _breathing.dispose();
    _bloom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionReduced(context)) return _halo(glowStillPhase, 0);
    return AnimatedBuilder(
      animation: Listenable.merge([_breathing, _bloom]),
      builder: (context, _) => _halo(Curves.easeInOut.transform(_breathing.value), _bloomSwell.transform(_bloom.value)),
    );
  }

  /// The halo at breath phase [t], lifted by the bloom's [swell]. A looping glow swells blur and spread with either; a
  /// breathing glow keeps its blur and breathes its alpha, and the bloom swells it as the loop does.
  Widget _halo(double t, double swell) {
    final lift = widget.loop ? math.max(t, swell) : swell;
    final restingAlpha = widget.loop ? 1.0 : 0.45 + 0.55 * t;
    final alpha = restingAlpha + (1 - restingAlpha) * swell;
    return CustomPaint(
      painter: HaloPainter(
        colour: widget.colour.withValues(alpha: widget.colour.a * alpha),
        blur: 34 + 30 * lift,
        spread: 2 + 12 * lift,
      ),
    );
  }
}

/// The halo as a radial gradient, not a blur: a Pi (Skia on GLES) cannot re-blur a 300 px circle every frame. It reads
/// as the blurred shadow it replaces (a circle grown by [spread], blurred by [blur]): the gradient follows that blur's
/// falloff, the normal curve at the blur's sigma, from the box's edge to transparent at radius + spread + blur.
class HaloPainter extends CustomPainter {
  const HaloPainter({required this.colour, required this.blur, required this.spread});

  final Color colour;
  final double blur;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    final box = size.shortestSide / 2;
    final outer = box + spread + blur;
    final middle = box + spread + blur / 2;
    final sigma = blur * 0.57735 + 0.5;
    Color at(double r) => colour.withValues(alpha: colour.a * _normal((box + spread - r) / sigma));
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: outer);
    final gradient = RadialGradient(
      colors: [at(box), at(box), at(middle), colour.withValues(alpha: 0)],
      stops: [0, box / outer, middle / outer, 1],
    );
    canvas.drawCircle(rect.center, outer, Paint()..shader = gradient.createShader(rect));
  }

  /// The normal cumulative distribution, by its logistic approximation (within 1 percent).
  static double _normal(double x) => 1 / (1 + math.exp(-1.702 * x));

  @override
  bool shouldRepaint(HaloPainter old) => old.colour != colour || old.blur != blur || old.spread != spread;
}
