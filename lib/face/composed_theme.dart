/// A face composed from a backdrop, an eye style and a mouth style. The widget still consumes a [FaceTheme]; this is
/// the one implementation, and the shipped looks are presets of it (styles.dart). With no mouth, the eyes pulse in
/// brightness with the viseme so speech still shows.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'face_theme.dart';
import 'styles/grille_mouth.dart';
import 'styles/line_mouths.dart';
import 'visemes.dart';

/// The viseme outlines every composed face tweens between; a mouth style maps them onto its slot or ignores them.
final composedMouthShapes = mouthShapes();

class ComposedTheme implements FaceTheme {
  const ComposedTheme({
    required this.backdrop,
    required this.eyeStyle,
    required this.mouthStyle,
    this.mouthScale = 1,
    this.palette = FacePalette.visage,
  });

  final FaceBackdrop backdrop;
  final EyeStyle eyeStyle;
  final MouthStyle mouthStyle;

  /// 1 regular; larger grows the mouth slot, up to what the backdrop allows.
  final double mouthScale;

  @override
  final FacePalette palette;

  @override
  FaceGeometry get geometry => backdrop.geometry;

  @override
  EyesPainter get eyes => _ComposedEyes(this);

  @override
  MouthPainter get mouth => _ComposedMouth(this);

  @override
  Map<int, List<Offset>> get mouthShapes => composedMouthShapes;

  FaceLayout layoutFor(FaceFrame frame) {
    final layout = backdrop.layout(frame.compact);
    final k = math.min(mouthScale, backdrop.maxMouthScale(frame.compact));
    return layout.withMouth(layout.mouth.scaled(k));
  }
}

class _ComposedEyes implements EyesPainter {
  const _ComposedEyes(this.theme);

  final ComposedTheme theme;

  @override
  void paint(Canvas canvas, FaceFrame frame) {
    theme.backdrop.paint(canvas, frame);
    final pulse = theme.mouthStyle is NoMouth && frame.mode == FaceMode.speaking;
    if (pulse) canvas.saveLayer(null, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6 + 0.4 * opening(frame)));
    theme.eyeStyle.paint(canvas, theme.layoutFor(frame), frame);
    if (pulse) canvas.restore();
  }
}

class _ComposedMouth implements MouthPainter {
  const _ComposedMouth(this.theme);

  final ComposedTheme theme;

  @override
  void paint(Canvas canvas, FaceFrame frame) => theme.mouthStyle.paint(canvas, theme.layoutFor(frame).mouth, frame);
}

/// The bare screen: the visage geometry, eyes at ±130 on row 190, the mouth box on row 480; the badge scales the
/// whole face, so the compact layout is the full one.
class PlainBackdrop implements FaceBackdrop {
  const PlainBackdrop();

  static const _eyeDx = 130.0;
  static const _eyeY = 190.0;
  static const _eyeRadius = 71.0;
  static const _mouthY = 480.0;
  static const _mouthWidth = 178.0;

  /// The viseme box is 200 wide and the rest smile 112 of it; the slot is the box at the width that makes the smile
  /// [_mouthWidth] wide.
  static const _mouthBoxScale = _mouthWidth / 112;

  static const layoutFull = FaceLayout(
    left: EyeSlot(Offset(frameWidth / 2 - _eyeDx, _eyeY), _eyeRadius),
    right: EyeSlot(Offset(frameWidth / 2 + _eyeDx, _eyeY), _eyeRadius),
    mouth: MouthSlot(Offset(frameWidth / 2, _mouthY), 200 * _mouthBoxScale, 100 * _mouthBoxScale),
  );

  @override
  FaceGeometry get geometry => const FaceGeometry(top: 75, height: 470, badgeRadius: 363);

  @override
  FaceLayout layout(bool compact) => layoutFull;

  @override
  double maxMouthScale(bool compact) => 2;

  @override
  void paint(Canvas canvas, FaceFrame frame) {}
}
