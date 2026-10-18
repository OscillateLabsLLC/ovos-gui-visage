/// The viseme outline as a mouth: hollow (the visage mouth) or filled. Both map [FaceFrame.lips] from the 200 x 100
/// viseme box onto the slot, so a bigger slot is a bigger mouth with a heavier stroke.
library;

import 'dart:math' as math;
import 'dart:ui';

import '../face_theme.dart';
import '../visemes.dart';

const _visemeBoxWidth = 200.0;
const _listenBars = 7;

/// The visage mouth stroke is 24 px on a slot 178 / 112 times the box; in box units that is this.
const _outlineStroke = 24 / (178 / 112);

void _enterSlot(Canvas canvas, MouthSlot slot) {
  final scale = slot.width / _visemeBoxWidth;
  canvas.translate(slot.centre.dx - mouthCx * scale, slot.centre.dy - mouthCy * scale);
  canvas.scale(scale, scale);
}

/// Seven accent bars where the mouth is, each breathing between 0.4 and 1.6 of its height on a 0.9 s cycle.
void paintListenBars(Canvas canvas, double elapsed) {
  final paint = Paint()..color = FaceColours.accent;
  for (var i = 0; i < _listenBars; i++) {
    final delay = i % 3 == 0 ? 0.6 : (i % 2 == 0 ? 0.3 : 0.0);
    final phase = ((elapsed + delay) / 0.9) * 2 * math.pi;
    final scaleY = 1.0 + 0.6 * -math.cos(phase);
    final rect = Rect.fromCenter(center: Offset(64 + i * 12, 50), width: 6, height: 24 * scaleY);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
  }
}

class OutlineMouth implements MouthStyle {
  const OutlineMouth();

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    canvas.save();
    _enterSlot(canvas, slot);
    if (frame.mode == FaceMode.listening) {
      paintListenBars(canvas, frame.elapsed);
    } else {
      final lips = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outlineStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = FaceColours.mouth;
      canvas.drawPath(toPath(frame.lips), lips);
    }
    canvas.restore();
  }
}

/// The same outline filled; listening is a breathing dot and thinking a short tilted line.
class SolidMouth implements MouthStyle {
  const SolidMouth();

  @override
  void paint(Canvas canvas, MouthSlot slot, FaceFrame frame) {
    canvas.save();
    _enterSlot(canvas, slot);
    final fill = Paint()..color = FaceColours.mouth;
    switch (frame.mode) {
      case FaceMode.listening:
        canvas.drawCircle(const Offset(mouthCx, mouthCy), 9 + 5 * math.sin(frame.elapsed * 3.2), fill);
      case FaceMode.thinking:
        canvas.translate(mouthCx, mouthCy);
        canvas.rotate(-0.12 + 0.04 * math.sin(frame.elapsed * 1.5));
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -6, 44, 12), const Radius.circular(6)), fill);
      case FaceMode.rest:
      case FaceMode.speaking:
        final path = toPath(frame.lips);
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8
            ..strokeJoin = StrokeJoin.round
            ..color = FaceColours.mouth,
        );
        canvas.drawPath(path, fill);
    }
    canvas.restore();
  }
}
