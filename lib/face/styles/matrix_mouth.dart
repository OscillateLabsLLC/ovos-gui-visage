/// The Mark 1's 32 x 8 LED mouth drawn from the firmware's bitmaps (mark1_images.g.dart) with its timings.
library;

import 'dart:ui';

import '../face_theme.dart';
import '../mark1_theme.dart';

const _mouthOn = Color(0xF5E1F3FF);
const _mouthOff = Color(0x09E1F3FF);
const _mouthGlow = Color(0xFFADDEFB);

class MatrixMouth implements MouthStyle {
  const MatrixMouth();

  /// LED radius 0.72 on a 2.5 pitch, in faceplate units.
  static const _ledRatio = 0.72 / 2.5;

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    final pitch = slot.width / mouthCols;
    final led = pitch * _ledRatio;
    final origin = slot.centre - Offset((mouthCols - 1) / 2 * pitch, (mouthRows - 1) / 2 * pitch);
    final rows = mouthFrame(frame.mode, frame.viseme, frame.elapsed);
    final off = Paint()..color = _mouthOff;
    final on = Paint()..color = _mouthOn;
    final glow = Paint()
      ..color = _mouthGlow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, led * 0.6);
    for (var y = 0; y < mouthRows; y++) {
      for (var x = 0; x < mouthCols; x++) {
        final at = origin + Offset(x * pitch, y * pitch);
        final lit = rows != null && (rows[y] >> x) & 1 == 1;
        if (lit) canvas.drawCircle(at, led, glow);
        canvas.drawCircle(at, led, lit ? on : off);
      }
    }
  }
}
