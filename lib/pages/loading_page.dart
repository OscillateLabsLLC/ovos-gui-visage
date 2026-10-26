/// SYSTEM_Loading (SPEC 8.2): thinking dots in a glowing ring chip, label beneath. Visage draws its own; OVOS's
/// loading.json Lottie is not played (decided 2026-10-25: it did not match the rest of the screen).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';
import 'template_text.dart';
import 'templates_model.dart';

/// A thinking dot at [pulse] (0 at rest, 1 at its peak). The still frame under reduced motion is the middle of a breath.
double dotOpacity(double pulse) => 0.25 + 0.75 * pulse;
double dotScale(double pulse) => 0.8 + 0.35 * pulse;
const _stillPulse = 0.5;

/// The hero chip of the loading, status and error templates.
const templateChipPx = 220.0;

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => LoadingPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [const _Dots(), const SizedBox(height: 28), TemplateLabel(loadingLabel(data))],
    );
  }
}

/// The thinking dots in a glowing ring chip.
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

/// The dots breathe in turn; under reduced motion the controller stops and every dot holds [_stillPulse].
class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionReduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Circle(
      size: templateChipPx,
      gradient: gradientFill,
      glow: const Glow(bloom: true),
      ring: const Ring(),
      children: [
        if (motionReduced(context))
          _row((_) => _stillPulse)
        else
          AnimatedBuilder(animation: _controller, builder: (context, _) => _row(_pulse)),
      ],
    );
  }

  Widget _row(double Function(int dot) pulse) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < 3; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Opacity(
            opacity: dotOpacity(pulse(i)),
            child: Transform.scale(
              scale: dotScale(pulse(i)),
              child: const DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: VisageColors.fg),
                child: SizedBox(width: 18, height: 18),
              ),
            ),
          ),
        ),
    ],
  );

  /// 0 at rest, 1 at the peak, 0.2 s apart per dot, peaking at 40 % of the cycle like the CSS keyframes.
  double _pulse(int i) {
    final t = (_controller.value - i / 6) % 1;
    if (t > 0.8) return 0;
    return t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.4;
  }
}
