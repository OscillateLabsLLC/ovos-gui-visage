/// Eyes that are plain shapes: solid blocks, glowing ovals and dots. Each reads its proportions from the slot.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../face_theme.dart';

/// Solid rounded squares. Listening grows them taller and brighter; thinking cuts the inner top corners away so the
/// eyes slant in; a blink is a slit. The cut is a path difference, so nothing is painted over the background.
class BlockEyes implements EyeStyle {
  const BlockEyes();

  static const _restAlpha = 0.95;

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    final think = frame.mode == FaceMode.thinking;
    final listen = frame.mode == FaceMode.listening;
    final sides = [1.0, -1.0];
    for (var i = 0; i < 2; i++) {
      final slot = layout.eyes[i], side = sides[i], r = slot.radius;
      final w = r * 1.1;
      final h = r * 1.3 * (listen ? 1.15 : 1) * frame.eyeOpen.clamp(0.06, 1.0) * (think ? 1.3 : 1);
      final centre = slot.centre - Offset(0, think ? r * 0.1 : 0);
      final box = Path()
        ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: centre, width: w, height: h), Radius.circular(r * 0.22)));
      var shape = box;
      if (think) {
        final top = centre.dy - h / 2 - 1;
        final cut = Path()
          ..moveTo(centre.dx + side * w / 2, top)
          ..lineTo(centre.dx - side * w / 2, top)
          ..lineTo(centre.dx + side * w / 2, top + 1 + h * 0.42)
          ..close();
        shape = Path.combine(PathOperation.difference, box, cut);
      }
      canvas.drawPath(shape, Paint()..color = listen ? frame.palette.mouth : frame.palette.eye.withValues(alpha: _restAlpha));
    }
  }
}

/// Elongated glowing ovals; expression is tilt and height. Listening lifts them, thinking narrows them and tilts
/// them inward, a blink flattens them.
class OvalEyes implements EyeStyle {
  const OvalEyes();

  /// How far the bright core sits from the accent towards the mouth colour.
  static const _coreLift = 0.835;

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    final think = frame.mode == FaceMode.thinking;
    final listen = frame.mode == FaceMode.listening;
    final sides = [1.0, -1.0];
    for (var i = 0; i < 2; i++) {
      final slot = layout.eyes[i], side = sides[i], r = slot.radius;
      final rx = r * 0.42;
      final ry = r * 0.72 * (listen ? 1.15 : 1) * frame.eyeOpen.clamp(0.05, 1.0) * (think ? 1.2 : 1);
      canvas.save();
      canvas.translate(slot.centre.dx, slot.centre.dy - (listen ? r * 0.12 : 0));
      canvas.rotate(side * (think ? 0.5 : 0.12));
      final oval = Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2);
      canvas.drawOval(
        oval,
        Paint()
          ..color = frame.palette.accent
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.25),
      );
      canvas.drawOval(oval, Paint()..color = frame.palette.accent);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: rx * 1.1, height: ry * 1.4),
        Paint()..color = Color.lerp(frame.palette.accent, frame.palette.mouth, _coreLift)!,
      );
      canvas.restore();
    }
  }
}

/// Two small filled dots. Listening grows them, thinking drifts them up and together, a blink makes them dashes.
class DotEyes implements EyeStyle {
  const DotEyes();

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    final think = frame.mode == FaceMode.thinking;
    final listen = frame.mode == FaceMode.listening;
    final sides = [1.0, -1.0];
    for (var i = 0; i < 2; i++) {
      final slot = layout.eyes[i], side = sides[i], r = slot.radius;
      final radius = r * 0.24 * (listen ? 1.35 : 1);
      final centre = slot.centre + Offset(think ? side * r * 0.14 : 0, think ? -r * 0.16 : 0);
      final dot = Rect.fromCenter(center: centre, width: radius * 2, height: radius * 2 * math.max(frame.eyeOpen, 0.12));
      canvas.drawOval(dot, Paint()..color = frame.palette.eye);
    }
  }
}
