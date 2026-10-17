/// Painters for the two icon layers whose SVG animated a shape attribute rather than a transform: the globe's
/// meridians (`rx` sweeping 0 -> 22 -> 0 with opacity 0.2 -> 0.9 -> 0.2, 6 s linear, three of them 2 s apart) and
/// the reminder's ticks (`stroke-dashoffset` 14 -> 0 by 12 %, held to 80 %, back to 14 at 100 %, 4.5 s ease-out,
/// 0.6 s apart). Values are those of assets/icon_sources/globe.svg and reminder.svg.
library;

import 'package:flutter/material.dart';

import 'motion.dart';

const _meridianColour = Color(0xFF9FD0FF);
const _tickColour = Color(0xFF3DDC84);
const _viewBox = 64.0;

/// The painter for an animated layer that is not a transform, or null when the layer is an ordinary SVG one.
/// [elapsed] null draws the reduced-motion still: meridians at rx 11 and opacity 0.7, ticks fully drawn.
CustomPainter? layerPainter(String icon, String? cls, int nth, Duration? elapsed) {
  if (icon == 'globe' && cls == 'meridian') return _MeridianPainter(nth, elapsed);
  if (icon == 'reminder' && cls == 'tick') return _TickPainter(nth, elapsed);
  return null;
}

const _turn = Motion(
  // rx rides the scale track.
  tracks: {
    Prop.scale: [(0.0, 0.0), (0.5, 22.0), (1.0, 0.0)],
    Prop.opacity: [(0.0, 0.2), (0.5, 0.9), (1.0, 0.2)],
  },
  period: Duration(seconds: 6),
);

class _MeridianPainter extends CustomPainter {
  _MeridianPainter(this.nth, this.elapsed);

  final int nth;
  final Duration? elapsed;

  /// `.m2 { animation-delay: -2s } .m3 { animation-delay: -4s }`: scale carries rx.
  Frame get _frame =>
      elapsed == null ? const Frame(scale: 11, opacity: 0.7) : _turn.at(elapsed! + Duration(seconds: 2 * (nth - 1)));

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _viewBox;
    final centre = Offset(32 * k, 32 * k);
    final frame = _frame;
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: 22 * k)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * k
      ..color = _meridianColour.withValues(alpha: frame.opacity);
    canvas.drawOval(Rect.fromCenter(center: centre, width: 2 * frame.scale * k, height: 44 * k), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MeridianPainter old) => old.elapsed != elapsed || old.nth != nth;
}

const _tick = Motion(
  // stroke-dashoffset rides the scale track: 14 hidden, 0 drawn.
  tracks: {
    Prop.scale: [(0.0, 14.0), (0.12, 0.0), (0.8, 0.0), (1.0, 14.0)],
  },
  period: Duration(milliseconds: 4500),
  curve: Curves.easeOut,
);
const _dash = 14.0;

class _TickPainter extends CustomPainter {
  _TickPainter(this.nth, this.elapsed);

  final int nth;
  final Duration? elapsed;

  /// `.t2 { animation-delay: 0.6s } .t3 { animation-delay: 1.2s }`.
  double get _dashOffset => elapsed == null ? 0 : _tick.at(elapsed! - Duration(milliseconds: 600 * (nth - 1))).scale;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _viewBox;
    final y = [18.0, 32.0, 46.0][nth - 1];
    final path = Path()
      ..moveTo(12.5 * k, y * k)
      ..lineTo(15 * k, (y + 2.5) * k)
      ..lineTo(20 * k, (y - 2.5) * k);
    final drawn = 1 - _dashOffset / _dash;
    if (drawn <= 0) return;
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _tickColour;
    canvas.drawPath(metric.extractPath(0, metric.length * drawn), paint);
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.elapsed != elapsed || old.nth != nth;
}
