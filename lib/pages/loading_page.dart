/// SYSTEM_Loading (SPEC 8.2): OVOS's own loading.json Lottie in a chip-sized circle, label beneath. Falls back to
/// thinking dots in a glowing ring chip when the animation is not in this install's cache.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../lottie/cache_lottie.dart';
import '../resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';
import 'template_text.dart';
import 'templates_model.dart';

const lottieChipPx = 220.0;
const loadingAnimation = '/res/system/qt5/animations/loading.json';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => LoadingPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: lottieChipPx,
          height: lottieChipPx,
          child: CacheLottie(file: cacheFile(loadingAnimation), loop: true, fitRing: true, fallback: const _Dots()),
        ),
        const SizedBox(height: 28),
        TemplateLabel(loadingLabel(data)),
      ],
    );
  }
}

/// The thinking dots in a glowing ring chip.
class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Circle(
      size: lottieChipPx,
      gradient: gradientFill,
      glow: const Glow(),
      ring: const Ring(),
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Opacity(
                    opacity: 0.25 + 0.75 * _pulse(i),
                    child: Transform.scale(
                      scale: 0.8 + 0.35 * _pulse(i),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: VisageColors.fg),
                        child: SizedBox(width: 18, height: 18),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 0 at rest, 1 at the peak, 0.2 s apart per dot, peaking at 40 % of the cycle like the CSS keyframes.
  double _pulse(int i) {
    final t = (_controller.value - i / 6) % 1;
    if (t > 0.8) return 0;
    return t < 0.4 ? t / 0.4 : 1 - (t - 0.4) / 0.4;
  }
}
