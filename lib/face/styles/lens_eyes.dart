/// The visage eyes: a grey ring with a white round-capped arc over its top half; blinks and narrows by squashing
/// vertically, the listen-start flash widens.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../face_theme.dart';

class LensEyes implements EyeStyle {
  const LensEyes();

  /// The measured face: ring radius 57 and stroke 28 inside a 71 slot.
  static const _ringRatio = 57 / 71;
  static const _strokeRatio = 28 / 71;

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    for (final slot in layout.eyes) {
      _paintEye(canvas, slot, frame);
    }
  }

  void _paintEye(Canvas canvas, EyeSlot slot, FaceFrame frame) {
    canvas.save();
    canvas.translate(slot.centre.dx, slot.centre.dy);
    canvas.scale(frame.eyeScale, frame.eyeScale * frame.eyeOpen);
    final radius = slot.radius * _ringRatio;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = slot.radius * _strokeRatio
      ..color = frame.palette.eyeDim;
    canvas.drawCircle(Offset.zero, radius, ring);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = slot.radius * _strokeRatio
      ..strokeCap = StrokeCap.round
      ..color = frame.palette.eye;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: radius), math.pi, math.pi, false, arc);
    canvas.restore();
  }
}
