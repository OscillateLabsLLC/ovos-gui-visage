/// The compact face on its dark disc (SPEC 5.3): the attention badge over content pages, and the whole window of a
/// collapsed peek widget.
library;

import 'package:flutter/widgets.dart';

import 'face.dart';
import 'face_theme.dart';

const badgeDisc = Color(0xEB141B24);

/// The face in frame coordinates, on the disc when [compact]; the attention overlay moves and scales this layer.
class BadgeFace extends StatelessWidget {
  const BadgeFace({super.key, required this.controller, required this.compact});

  final FaceController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final geometry = controller.theme.geometry;
    return Stack(
      alignment: Alignment.topLeft,
      children: [
        if (compact) Positioned.fill(child: CustomPaint(painter: _DiscPainter(geometry.centre, geometry.badgeRadius))),
        Face(controller: controller, compact: compact),
      ],
    );
  }
}

/// The badge alone, its disc filling the box (scaled to fit).
class FaceBadge extends StatelessWidget {
  const FaceBadge({super.key, required this.controller});

  final FaceController controller;

  @override
  Widget build(BuildContext context) {
    final geometry = controller.theme.geometry;
    final radius = geometry.badgeRadius;
    final corner = geometry.centre - Offset(radius, radius);
    return FittedBox(
      child: SizedBox.square(
        dimension: 2 * radius,
        child: Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -corner.dx,
              top: -corner.dy,
              width: frameWidth,
              height: frameHeight,
              child: BadgeFace(controller: controller, compact: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  _DiscPainter(this.centre, this.radius);

  final Offset centre;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(centre, radius, Paint()..color = badgeDisc);

  @override
  bool shouldRepaint(_DiscPainter old) => old.centre != centre || old.radius != radius;
}
