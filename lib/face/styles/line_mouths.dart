/// Mouths that read the viseme as a signal rather than an outline: a waveform stroke and an equaliser of bars. Both
/// take the opening, width and corner lift from the viseme shape table so they move with the same speech.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../face_theme.dart';
import '../visemes.dart';

const _tau = 2 * math.pi;

MouthShape _shape(FaceFrame frame) => mouthShapeSpecs[frame.mode == FaceMode.speaking ? frame.viseme : restCode]!;

/// 0 closed to 1 the widest viseme.
double opening(FaceFrame frame) => frame.mode == FaceMode.speaking ? (_shape(frame).up + _shape(frame).down) / 60 : 0;

/// 1 at the rest smile's width.
double widthRatio(FaceFrame frame) => frame.mode == FaceMode.speaking ? _shape(frame).w / 56 : 1;

/// 1 at the rest smile's corner lift, 0 for a viseme with none.
double smileRatio(FaceFrame frame) => frame.mode == FaceMode.speaking ? _shape(frame).smile / 7 : 1;

/// One stroke on a shallow smile. Speaking sets its amplitude from the viseme opening and its span from the viseme
/// width, and the smile flattens as the viseme opens. Listening is a low accent ripple, thinking three dots pulsing
/// in turn.
class WaveformMouth implements MouthStyle {
  const WaveformMouth();

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    if (frame.mode == FaceMode.thinking) {
      _paintDots(canvas, slot, frame.elapsed, frame.palette.mouth);
      return;
    }
    final listen = frame.mode == FaceMode.listening;
    final span = slot.width * 0.6 * (listen ? 1 : widthRatio(frame));
    final amp = listen ? slot.height * 0.08 : slot.height * 0.42 * opening(frame);
    final cycles = listen ? 3 : 2.5;
    final lift = slot.height * 0.16 * (listen ? 1 : smileRatio(frame));
    final speed = listen ? 6 : 14;
    final path = Path();
    const n = 64;
    for (var i = 0; i <= n; i++) {
      final u = i / n * 2 - 1;
      final window = 1 - u * u;
      final y = slot.centre.dy - lift * (u * u - 0.5) - amp * window * math.sin(u * cycles * math.pi + frame.elapsed * speed);
      final x = slot.centre.dx + u * span / 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = slot.width * 0.05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = listen ? frame.palette.accent : frame.palette.mouth,
    );
  }

  void _paintDots(Canvas canvas, MouthSlot slot, double elapsed, Color colour) {
    for (var i = -1; i <= 1; i++) {
      final alpha = 0.35 + 0.65 * math.max(0, math.sin(elapsed * 4 - i * 1.1));
      final at = slot.centre + Offset(i * slot.width * 0.13, 0);
      canvas.drawCircle(at, slot.width * 0.035, Paint()..color = colour.withValues(alpha: alpha));
    }
  }
}

/// A vertical equaliser: the viseme opening sets the heights and its width how many bars rise. Stubs along a shallow
/// smile at rest, the breathing accent bars when listening, one bar scanning across when thinking.
class BarsMouth implements MouthStyle {
  const BarsMouth();

  static const _bars = 9;

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    final span = slot.width * 0.58, pitch = span / (_bars - 1), barWidth = pitch * 0.42;
    final listen = frame.mode == FaceMode.listening, think = frame.mode == FaceMode.thinking;
    final paint = Paint()..color = listen ? frame.palette.accent : frame.palette.mouth;
    final scan = (frame.elapsed * 6).round() % (2 * (_bars - 1));
    for (var i = 0; i < _bars; i++) {
      final u = (i - (_bars - 1) / 2) / ((_bars - 1) / 2);
      final height = _height(frame, i, u, listen, think, scan, slot.height);
      final smile = slot.height * 0.14 * smileRatio(frame) * (u * u - 0.5);
      final rect = Rect.fromLTWH(
        slot.centre.dx + u * span / 2 - barWidth / 2,
        slot.centre.dy - smile - height / 2,
        barWidth,
        height,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)), paint);
    }
  }

  double _height(FaceFrame frame, int i, double u, bool listen, bool think, int scan, double h) {
    final stub = h * 0.07;
    if (listen) {
      final delay = i % 3 == 0 ? 0.6 : (i % 2 == 0 ? 0.3 : 0.0);
      return h * 0.16 * (1 + 0.6 * -math.cos(((frame.elapsed + delay) / 0.9) * _tau));
    }
    if (think) return scan == i || scan == 2 * (_bars - 1) - i ? h * 0.3 : stub;
    if (frame.mode == FaceMode.speaking && u.abs() <= widthRatio(frame) + 0.01) {
      return stub + h * 0.65 * opening(frame) * (1 - u * u) * (0.85 + 0.15 * math.sin(frame.elapsed * 22 + i * 1.7));
    }
    return stub;
  }
}
