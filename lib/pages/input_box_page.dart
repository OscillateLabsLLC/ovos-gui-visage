/// SYSTEM_InputBox (SPEC 8.2), display-only: a glowing ring chip with a listening microphone, the title and
/// placeholder as a prompt beneath, confirm and exit as muted hints. Nothing is clickable (SPEC 1).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';
import 'template_text.dart';
import 'templates_model.dart';

class InputBoxPage extends StatelessWidget {
  const InputBoxPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => InputBoxPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final model = inputBoxModel(data);
    final hints = [model.confirm, model.exit].where((s) => s.isNotEmpty).join('  ·  ');
    return StaggerEnter(
      gap: 20,
      children: [
        Circle(size: 200, gradient: gradientFill, glow: const Glow(), ring: const Ring(), children: [_PulsingMic()]),
        if (model.title.isNotEmpty) Text(model.title, textAlign: TextAlign.center, style: VisageText.fg(30)),
        if (model.placeholder.isNotEmpty)
          Text(model.placeholder, textAlign: TextAlign.center, style: VisageText.muted(22).copyWith(fontStyle: FontStyle.italic)),
        if (hints.isNotEmpty) TemplateHint(hints),
      ],
    );
  }
}

/// The mic icon with the three sound waves the SVG used to animate in CSS: rings expanding and fading, 0.8 s apart.
class _PulsingMic extends StatefulWidget {
  @override
  State<_PulsingMic> createState() => _PulsingMicState();
}

class _PulsingMicState extends State<_PulsingMic> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(animation: _controller, builder: (context, _) => CustomPaint(size: const Size(110, 110), painter: _WavePainter(_controller.value))),
          icon('mic', size: 110),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // The SVG's waves: r 22 of a 64 box around (32, 26), scaling 0.55 -> 1.35 while fading 0.9 -> 0.
    final k = size.width / 64;
    final centre = Offset(32 * k, 26 * k);
    for (var i = 0; i < 3; i++) {
      final phase = Curves.easeOut.transform((t - i / 3) % 1);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * k
        ..color = VisageColors.accent.withValues(alpha: 0.9 * (1 - phase));
      canvas.drawCircle(centre, 22 * k * (0.55 + 0.8 * phase), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.t != t;
}
