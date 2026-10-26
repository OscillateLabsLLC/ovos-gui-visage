/// SYSTEM_Status (SPEC 8.2): OVOS's status-success / status-fail Lottie, played once and held on its last frame, in
/// a chip-sized circle with the label beneath. Without the file: an accent ring with a check, or a dimmed ring with
/// a cross, blooming as it arrives (SPEC 9).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../lottie/cache_lottie.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'loading_page.dart' show lottieChipPx;
import 'page.dart';
import 'reduced_motion.dart';
import 'template_text.dart';
import 'templates_model.dart';

String statusAnimation(bool ok) => '/res/system/qt5/animations/status-${ok ? 'success' : 'fail'}.json';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => StatusPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:ok, :label) = statusModel(data);
    return Center(
      child: StaggerOrStill(
        children: [
          SizedBox(
            width: lottieChipPx,
            height: lottieChipPx,
            // Keyed on ok so a change replays the one-shot from the start.
            child: CacheLottie(key: ValueKey(ok), resource: statusAnimation(ok), loop: false, fallback: _Glyph(ok)),
          ),
          TemplateLabel(label),
        ],
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.ok);

  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ok ? 1 : 0.45,
      child: Circle(
        size: lottieChipPx,
        gradient: gradientFill,
        glow: const Glow(bloom: true),
        ring: const Ring(),
        children: [SizedBox.expand(child: CustomPaint(painter: _GlyphPainter(ok)))],
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.ok);

  final bool ok;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = VisageColors.fg;
    final path = Path();
    if (ok) {
      path
        ..moveTo(34 * k, 52 * k)
        ..lineTo(46 * k, 64 * k)
        ..lineTo(68 * k, 38 * k);
    } else {
      path
        ..moveTo(38 * k, 38 * k)
        ..lineTo(62 * k, 62 * k)
        ..moveTo(62 * k, 38 * k)
        ..lineTo(38 * k, 62 * k);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.ok != ok;
}
