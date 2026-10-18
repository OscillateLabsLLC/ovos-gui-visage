/// Mouths that are not mouths: a speaker grille, a voice ring, and none at all.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../face_theme.dart';
import 'line_mouths.dart';

const _tau = 2 * math.pi;

/// Horizontal speaker slats. Speaking lights them outward from the centre by the viseme opening, listening breathes
/// them in the accent, thinking scans one slat up and down.
class GrilleMouth implements MouthStyle {
  const GrilleMouth();

  static const _slats = 7;

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    final slat = slot.height * 0.075, gap = slat * 0.7;
    final listen = frame.mode == FaceMode.listening, think = frame.mode == FaceMode.thinking;
    final span = slot.width * 0.5 * (frame.mode == FaceMode.speaking ? 0.6 + 0.4 * widthRatio(frame) : 1);
    final scan = (frame.elapsed * 7).floor() % (2 * (_slats - 1));
    final scanRow = scan < _slats ? scan : 2 * (_slats - 1) - scan;
    final colour = listen ? frame.palette.accent : frame.palette.mouth;
    for (var j = 0; j < _slats; j++) {
      final d = (j - (_slats - 1) / 2).abs();
      var lit = 0.18;
      if (listen) {
        lit = 0.35 + 0.45 * (0.5 + 0.5 * math.sin(frame.elapsed * 4 - d));
      } else if (think) {
        lit = j == scanRow ? 1 : 0.18;
      } else if (frame.mode == FaceMode.speaking) {
        lit = d <= opening(frame) * (_slats - 1) / 2 + 0.01 ? 1 : 0.18;
      }
      final y = slot.centre.dy + (j - (_slats - 1) / 2) * (slat + gap);
      final rect = Rect.fromCenter(center: Offset(slot.centre.dx, y), width: span, height: slat);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(slat / 2)), Paint()..color = colour.withValues(alpha: lit));
    }
  }
}

/// A ring that swells with the viseme and throws concentric rings while speaking. Listening is a breathing accent
/// ring, thinking a rotating arc.
class OrbMouth implements MouthStyle {
  const OrbMouth();

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    final r0 = math.min(slot.width, slot.height) * 0.3;
    final listen = frame.mode == FaceMode.listening;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = slot.width * 0.04
      ..strokeCap = StrokeCap.round
      ..color = listen ? frame.palette.accent : frame.palette.mouth;
    if (frame.mode == FaceMode.thinking) {
      canvas.drawArc(Rect.fromCircle(center: slot.centre, radius: r0), frame.elapsed * 3, _tau * 0.7, false, stroke);
      return;
    }
    final open = opening(frame);
    final r = listen ? r0 * (1 + 0.12 * math.sin(frame.elapsed * 3)) : r0 * (1 + 0.35 * open);
    if (frame.mode == FaceMode.rest) stroke.color = stroke.color.withValues(alpha: 0.7);
    canvas.drawCircle(slot.centre, r, stroke);
    if (frame.mode != FaceMode.speaking || open <= 0.1) return;
    for (var k = 0; k < 3; k++) {
      final phase = (frame.elapsed * 1.4 + k / 3) % 1;
      final ripple = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth
        ..color = frame.palette.mouth.withValues(alpha: (1 - phase) * 0.6 * open);
      canvas.drawCircle(slot.centre, r + phase * r0 * 1.6, ripple);
    }
  }
}

/// No mouth; the composed theme pulses the eyes with the viseme instead.
class NoMouth implements MouthStyle {
  const NoMouth();

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {}
}
