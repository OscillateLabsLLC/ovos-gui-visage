/// ovos.common_play / busy: OCP searching for media (SPEC 8.6). OCP's own installing.json Lottie, as busy.qml plays
/// it, in a chip-sized circle under a breathing halo with OCP's label beneath; a turning arc around thinking dots
/// when the animation is not cached.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../json.dart';
import '../lottie/cache_lottie.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'ocp_browse_model.dart';
import 'page.dart';

const installingAnimation = '/res/ovos.common_play/qt5/animations/installing.json';
const _chipPx = 200.0;

class OcpBusyPage extends StatelessWidget {
  const OcpBusyPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => OcpBusyPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Circle(
          size: _chipPx,
          glow: const Glow(),
          children: [
            SizedBox.expand(
              child: CacheLottie(resource: installingAnimation, loop: true, fitRing: true, fallback: const _TurningArc()),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(busyLabel(data), textAlign: TextAlign.center, style: VisageText.muted(22)),
      ],
    );
  }
}

/// A dashed arc turning around three breathing dots.
class _TurningArc extends StatefulWidget {
  const _TurningArc();

  @override
  State<_TurningArc> createState() => _TurningArcState();
}

class _TurningArcState extends State<_TurningArc> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  /// Turns unless reduced motion is on; then the arc and dots hold the cycle's first frame.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 0;
    } else {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: _controller.value * 1.5 * math.pi,
            child: const Ring(fraction: 0.25, track: Colors.transparent),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            children: [
              for (var i = 0; i < 3; i++)
                Opacity(
                  opacity: 0.25 + 0.75 * (0.5 - 0.5 * math.cos(2 * math.pi * ((_controller.value - i / 6) % 1))),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, color: VisageColors.fg),
                    child: SizedBox(width: 16, height: 16),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
