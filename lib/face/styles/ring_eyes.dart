/// LED eyes: the Mark 1's 12-pixel ring with the firmware's narrow and blink order, and an 8 x 8 matrix eye.
library;

import 'dart:ui';

import '../face_theme.dart';
import '../mark1_theme.dart';

const _trackIdle = Color(0x0DFFFFFF);

/// A 12-pixel NeoPixel ring; the slot is the ring plus one LED radius (faceplate units 13.5 + 1.6). In the compact
/// badge the LEDs are larger and lit in the bright matrix colour, since the ring's dim grey does not read at 96 px.
class RingEyes implements EyeStyle {
  const RingEyes();

  static const _full = (ring: 13.5 / 15.1, led: 1.6 / 15.1);
  static const _compact = (ring: 0.85, led: 0.15);

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    final depth = narrowDepth(frame.eyeOpen);
    final lit = frame.compact ? frame.palette.matrix : frame.palette.led;
    final ratios = frame.compact ? _compact : _full;
    for (final slot in layout.eyes) {
      _paintRing(canvas, slot, depth, lit, ratios);
    }
  }

  void _paintRing(Canvas canvas, EyeSlot slot, int depth, Color lit, ({double ring, double led}) ratios) {
    final radius = slot.radius * ratios.ring;
    final led = slot.radius * ratios.led;
    final anyLit = depth < narrowDepthMax;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius / 3
      ..color = anyLit ? lit.withValues(alpha: 0.09) : _trackIdle;
    canvas.drawCircle(slot.centre, radius, track);
    final glow = Paint()
      ..color = lit.withValues(alpha: 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, led * 0.75);
    final on = Paint()..color = lit;
    final off = Paint()..color = HardwareColours.unlit;
    for (var slotIndex = 0; slotIndex < ringSize; slotIndex++) {
      final at = ringPixel(slot.centre, radius, slotIndex);
      if (pixelLit(slotIndex, depth)) {
        canvas.drawCircle(at, led, glow);
        canvas.drawCircle(at, led, on);
      } else {
        canvas.drawCircle(at, led, off);
      }
    }
  }
}

/// An 8 x 8 matrix eye: a lit disc with a dark pupil. A blink rolls rows off from the top and bottom, thinking
/// shifts the pupil up and sideways under a squint, listening brightens the glow.
class PixelEyes implements EyeStyle {
  const PixelEyes();

  static const _cells = 8;

  @override
  void paint(Canvas canvas, FaceLayout layout, FaceFrame frame) {
    final think = frame.mode == FaceMode.thinking;
    final open = frame.eyeOpen.clamp(0.02, 1.0) * (think ? 1.3 : 1);
    final pupilDx = think ? 1 : 0, pupilDy = think ? -1 : 0;
    final glowSize = frame.mode == FaceMode.listening ? 3.5 : 1.8;
    for (final slot in layout.eyes) {
      final pitch = slot.radius * 2 / (_cells + 1);
      final led = pitch * 0.36;
      final panel = Rect.fromCenter(center: slot.centre, width: pitch * 9, height: pitch * 9);
      canvas.drawRRect(RRect.fromRectAndRadius(panel, Radius.circular(pitch)), Paint()..color = HardwareColours.panel);
      final glow = Paint()
        ..color = frame.palette.matrix
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, led * glowSize);
      for (var row = 0; row < _cells; row++) {
        for (var col = 0; col < _cells; col++) {
          final dx = col - 3.5, dy = row - 3.5;
          final inDisc = dx * dx + dy * dy <= 3.9 * 3.9;
          final pupil = (col == 3 + pupilDx || col == 4 + pupilDx) && (row == 3 + pupilDy || row == 4 + pupilDy);
          final lit = inDisc && !pupil && dy.abs() < 4 * open;
          final at = slot.centre + Offset(dx * pitch, dy * pitch);
          if (lit) canvas.drawCircle(at, led, glow);
          canvas.drawCircle(at, led, Paint()..color = lit ? frame.palette.matrix : HardwareColours.unlit);
        }
      }
    }
  }
}
