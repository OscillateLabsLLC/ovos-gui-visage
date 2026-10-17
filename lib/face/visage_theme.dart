/// The visage face (ovos-visage SPEC 9, face.js VISAGE_FACE): two shaded ring eyes and a white hollow mouth, in the
/// upper half of the 480 x 800 frame. Eyes, strokes and the rest smile are the measured 2018 Kickstarter face; the
/// spacing and the open mouth deviate on purpose so the face reads round and the viseme motion stays visible.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'face_theme.dart';
import 'visemes.dart';

const _eyeDx = 130.0;
const _eyeY = 190.0;
const _eyeRadius = 57.0;
const _eyeStroke = 28.0;
const _eyeTop = Color(0xFFF5F5F5);
const _eyeBottom = Color(0xFF6D6D6D);
const _mouthY = 480.0;
const _mouthWidth = 178.0;
const _mouthStroke = 24.0;
const _lipColor = Color(0xFFFFFFFF);
const _accent = Color(0xFF1E9BFF);
const _listenBars = 7;

class VisageTheme implements FaceTheme {
  const VisageTheme();

  @override
  FaceGeometry get geometry => const FaceGeometry(top: 75, height: 470, badgeRadius: 363);

  @override
  EyesPainter get eyes => const RingEyes();

  @override
  MouthPainter get mouth => const HollowMouth();

  @override
  Map<int, List<Offset>> get mouthShapes => visageMouthShapes;
}

final visageMouthShapes = mouthShapes();

/// A grey ring with a white round-capped arc over its top half; blinks and narrows by squashing vertically.
class RingEyes implements EyesPainter {
  const RingEyes();

  @override
  void paint(Canvas canvas, FaceFrame frame) {
    for (final sign in const [-1, 1]) {
      _paintEye(canvas, Offset(frameWidth / 2 + sign * _eyeDx, _eyeY), frame);
    }
  }

  void _paintEye(Canvas canvas, Offset centre, FaceFrame frame) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(frame.eyeScale, frame.eyeScale * frame.eyeOpen);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _eyeStroke
      ..color = _eyeBottom;
    canvas.drawCircle(Offset.zero, _eyeRadius, ring);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _eyeStroke
      ..strokeCap = StrokeCap.round
      ..color = _eyeTop;
    canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: _eyeRadius), math.pi, math.pi, false, arc);
    canvas.restore();
  }
}

/// The lips as a round-capped outline scaled from the viseme box to [_mouthWidth]; listening swaps in audio bars.
class HollowMouth implements MouthPainter {
  const HollowMouth();

  static double get _scale {
    final xs = visageMouthShapes[restCode]!.map((p) => p.dx);
    return _mouthWidth / (xs.reduce(math.max) - xs.reduce(math.min));
  }

  @override
  void paint(Canvas canvas, FaceFrame frame) {
    final scale = _scale;
    canvas.save();
    canvas.translate(frameWidth / 2 - mouthCx * scale, _mouthY - mouthCy * scale);
    canvas.scale(scale);
    if (frame.mode == FaceMode.listening) {
      _paintBars(canvas, frame.elapsed);
    } else {
      final lips = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _mouthStroke / scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = _lipColor;
      canvas.drawPath(toPath(frame.lips), lips);
    }
    canvas.restore();
  }

  /// Seven accent bars where the mouth is, each breathing between 0.4 and 1.6 of its height on a 0.9 s cycle.
  void _paintBars(Canvas canvas, double elapsed) {
    final paint = Paint()..color = _accent;
    for (var i = 0; i < _listenBars; i++) {
      final delay = i % 3 == 0 ? 0.6 : (i % 2 == 0 ? 0.3 : 0.0);
      final phase = ((elapsed + delay) / 0.9) * 2 * math.pi;
      final scaleY = 1.0 + 0.6 * -math.cos(phase);
      final rect = Rect.fromCenter(center: Offset(64 + i * 12, 50), width: 6, height: 24 * scaleY);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
    }
  }
}
