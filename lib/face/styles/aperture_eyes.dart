/// Lens eyes of the camera kind: an aperture with iris blades, two of them or one at the midpoint, and the visor,
/// one bar across both slots.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../face_theme.dart';

const _tau = 2 * math.pi;

/// A camera lens: housing, glass, iris blades and a dark pupil with a highlight. Listening opens the iris wide,
/// thinking contracts it and lets the pupil dart, a blink closes the blades. [single] draws one bigger lens at the
/// midpoint of the two slots with the accent in the glass.
class ApertureEyes implements EyeStyle {
  const ApertureEyes({this.single = false});

  final bool single;

  static const _blades = 8;
  static const _glass = Color(0xFFDFE7EF);
  static const _pupil = Color(0xFF0B0C0F);

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    if (single) {
      final a = layout.left, b = layout.right;
      _paintLens(canvas, EyeSlot((a.centre + b.centre) / 2, a.radius * 1.5), frame, frame.palette.accent);
      return;
    }
    for (final slot in layout.eyes) {
      _paintLens(canvas, slot, frame, _glass);
    }
  }

  void _paintLens(Canvas canvas, EyeSlot slot, FaceFrame frame, Color glass) {
    final think = frame.mode == FaceMode.thinking;
    final listen = frame.mode == FaceMode.listening;
    final open = math.max(0.03, frame.eyeOpen) * (listen ? 1.2 : 1) * (think ? 0.55 : 1);
    final r = slot.radius, radius = r * 0.78;
    final iris = radius * 0.92 * math.min(open, 1);
    final spin = frame.elapsed * 0.3 + open * 1.2;
    canvas.save();
    canvas.translate(slot.centre.dx, slot.centre.dy);
    canvas.drawCircle(Offset.zero, r * 0.92, Paint()..color = HardwareColours.housing);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = glass);
    final blades = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: radius))
      ..addPolygon(_corners(iris, spin), true);
    canvas.drawPath(blades, Paint()..color = HardwareColours.blade);
    final seam = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..color = _pupil;
    for (var k = 0; k < _blades; k++) {
      final a = spin + k * _tau / _blades;
      canvas.drawLine(Offset.fromDirection(a, iris), Offset.fromDirection(a + 0.3, radius), seam);
    }
    final dart = think ? math.sin(frame.elapsed * 3) * iris * 0.25 : 0.0;
    canvas.drawCircle(Offset(dart, 0), iris * 0.62, Paint()..color = _pupil);
    canvas.drawCircle(
      Offset(dart, 0),
      iris * 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.03
        ..color = frame.palette.mouth.withValues(alpha: 0.35),
    );
    canvas.drawCircle(
      Offset(-iris * 0.28 + dart, -iris * 0.3),
      iris * 0.12,
      Paint()..color = frame.palette.mouth.withValues(alpha: 0.85),
    );
    canvas.restore();
  }

  List<Offset> _corners(double radius, double spin) => [
    for (var k = 0; k < _blades; k++) Offset.fromDirection(spin + k * _tau / _blades, radius),
  ];
}

/// One bar across both eye slots, brightest in the middle. Listening sweeps a scanner highlight end to end, thinking
/// contracts the bar to its centre and pulses, a blink thins it to a line.
class VisorEyes implements EyeStyle {
  const VisorEyes();

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    final a = layout.left, b = layout.right, r = a.radius;
    final think = frame.mode == FaceMode.thinking;
    final span = (b.centre.dx - a.centre.dx + r * 1.2) * (think ? 0.42 : 1);
    final centre = Offset((a.centre.dx + b.centre.dx) / 2, a.centre.dy);
    final pulse = think ? 0.65 + 0.35 * math.sin(frame.elapsed * 5) : 1.0;
    final h = r * 0.5 * frame.eyeOpen.clamp(0.06, 1.0) * (think ? 0.8 : 1);
    final bar = Rect.fromCenter(center: centre, width: span, height: h);
    final shade = Paint()
      ..shader = Gradient.linear(
        bar.centerLeft,
        bar.centerRight,
        [frame.palette.eyeDim, frame.palette.eye, frame.palette.eyeDim],
        const [0, 0.5, 1],
      )
      ..color = Color.fromRGBO(0, 0, 0, pulse);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(h / 2)), shade);
    if (frame.mode == FaceMode.listening) {
      final x = centre.dx + (span / 2 - h) * math.sin(frame.elapsed * 2.4);
      final at = Offset(x, centre.dy);
      canvas.drawCircle(
        at,
        h * 1.4,
        Paint()..shader = Gradient.radial(at, h * 1.4, [frame.palette.accent, frame.palette.accent.withValues(alpha: 0)]),
      );
    }
  }
}
