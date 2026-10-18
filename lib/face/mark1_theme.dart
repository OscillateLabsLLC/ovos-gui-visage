/// The Mycroft Mark 1 face: two 12-pixel NeoPixel eye rings and a 32 x 8 LED mouth behind the dark faceplate glass,
/// drawn from the firmware's own bitmaps (mark1_images.g.dart) with its timings and its narrow/blink pixel order,
/// as ported in ovos-virtual-mark1. The full layout is the faceplate at its true proportions; the compact badge
/// stacks the eyes over the mouth so both fit the disc.
library;

import 'dart:math' as math;
import 'dart:ui';

import 'face_theme.dart';
import 'mark1_images.g.dart';
import 'visage_theme.dart';

const ringSize = 12;
const mouthCols = 32;
const mouthRows = 8;
const listenStepMs = 70;
const thinkStepMs = 120;
const narrowDepthMax = 3;

/// Faceplate units (ovos-virtual-mark1 faceplate.js): the rim spans 164.38 x 57.37.
const _plateScale = 2.6;
const _plateWidth = 164.38;
const _plateHeight = 57.37;
const _plateCentre = Offset(frameWidth / 2, 300);
const _ringX = [140.19, 24.19];
const _ringY = 28.69;
const _ringRadius = 13.5;
const _eyeLedRadius = 1.6;
const _mouthOrigin = Offset(43.34, 19.84);
const _mouthPitch = 2.5;
const _mouthLedRadius = 0.72;
const _micCentre = Offset(82.19, 10.8);
const _micDots = 30;
const _micRadius = 4.4;
const _micDotRadius = 0.46;
const _goldenAngle = 2.399963;

const _eyeColour = Color(0xFF70656A); // the firmware's default (112, 101, 106) at full brightness
const _eyeOff = Color(0xFF12171C);
const _mouthOn = Color(0xF5E1F3FF);
const _mouthOff = Color(0x09E1F3FF);
const _mouthGlow = Color(0xFFADDEFB);
const _trackIdle = Color(0x0DFFFFFF);
const _reflection = Color(0x17FFFFFF);
const _grille = Color(0xFF070B0D);

class Mark1Theme implements FaceTheme {
  const Mark1Theme();

  @override
  FaceGeometry get geometry =>
      const FaceGeometry(top: 300 - _plateHeight * _plateScale / 2, height: _plateHeight * _plateScale, badgeRadius: 115);

  @override
  EyesPainter get eyes => const Mark1Eyes();

  @override
  MouthPainter get mouth => const Mark1Mouth();

  /// The widget tweens outlines for every theme; this one paints bitmaps by viseme code and ignores them.
  @override
  Map<int, List<Offset>> get mouthShapes => visageMouthShapes;
}

/// Where the LEDs sit, in frame pixels. [rings] is right then left, as the firmware numbers them.
class Mark1Layout {
  const Mark1Layout({
    required this.rings,
    required this.ringRadius,
    required this.eyeLed,
    required this.mouthOrigin,
    required this.pitch,
    required this.mouthLed,
    required this.plate,
  });

  final List<Offset> rings;
  final double ringRadius;
  final double eyeLed;
  final Offset mouthOrigin;
  final double pitch;
  final double mouthLed;

  /// The faceplate's top-left and scale, or null for the badge (the disc is the plate there).
  final (Offset, double)? plate;

  static Mark1Layout get full {
    final origin = _plateCentre - const Offset(_plateWidth / 2, _plateHeight / 2) * _plateScale;
    Offset at(double x, double y) => origin + Offset(x, y) * _plateScale;
    return Mark1Layout(
      rings: [at(_ringX[0], _ringY), at(_ringX[1], _ringY)],
      ringRadius: _ringRadius * _plateScale,
      eyeLed: _eyeLedRadius * _plateScale,
      mouthOrigin: at(_mouthOrigin.dx, _mouthOrigin.dy),
      pitch: _mouthPitch * _plateScale,
      mouthLed: _mouthLedRadius * _plateScale,
      plate: (origin, _plateScale),
    );
  }

  static Mark1Layout get compact => Mark1Layout(
    rings: [_plateCentre + const Offset(58, -46), _plateCentre + const Offset(-58, -46)],
    ringRadius: 30,
    eyeLed: 3.6,
    mouthOrigin: _plateCentre + const Offset(-(mouthCols - 1) * 6 / 2, 38 - (mouthRows - 1) * 6 / 2),
    pitch: 6,
    mouthLed: 1.8,
    plate: null,
  );

  static Mark1Layout of(FaceFrame frame) => frame.compact ? compact : full;
}

/// Pixel [slot] of a ring sits counter-clockwise from just past the top, as faceplate.js places them.
Offset ringPixel(Offset centre, double radius, int slot) {
  final theta = (90 + 360 / ringSize * (slot + 0.5)) * math.pi / 180;
  return Offset(centre.dx + radius * math.cos(theta), centre.dy - radius * math.sin(theta));
}

/// How many pixel pairs the firmware's narrow has turned off: 0 open, 2 the squint, 3 closed (a blink's deepest step).
int narrowDepth(double eyeOpen) {
  if (eyeOpen <= 0.2) return 3;
  if (eyeOpen <= 0.75) return 2;
  if (eyeOpen <= 0.92) return 1;
  return 0;
}

/// Firmware _set_eye_narrow: at depth p the pixels p, 11-p, 6+p and 5-p are off, so the top and bottom close first.
bool pixelLit(int slot, int depth) {
  for (var p = 0; p < depth; p++) {
    if (slot == p || slot == ringSize - 1 - p || slot == ringSize ~/ 2 + p || slot == ringSize ~/ 2 - 1 - p) return false;
  }
  return true;
}

/// The mouth bitmap for a frame: the listen loop, the think bounce (0..6, 6..0), the viseme while speaking, blank at
/// rest, with the firmware's step times.
List<int>? mouthFrame(FaceMode mode, int viseme, double elapsed) {
  switch (mode) {
    case FaceMode.listening:
      return listenFrames[(elapsed * 1000 ~/ listenStepMs) % listenFrames.length];
    case FaceMode.thinking:
      final steps = thinkFrames.length * 2;
      final step = (elapsed * 1000 ~/ thinkStepMs) % steps;
      return thinkFrames[step < thinkFrames.length ? step : steps - 1 - step];
    case FaceMode.speaking:
      return visemeFrames[viseme.clamp(0, visemeFrames.length - 1)];
    case FaceMode.rest:
      return null;
  }
}

class Mark1Eyes implements EyesPainter {
  const Mark1Eyes();

  @override
  void paint(Canvas canvas, FaceFrame frame) {
    final layout = Mark1Layout.of(frame);
    final plate = layout.plate;
    if (plate != null) _paintPlate(canvas, plate.$1, plate.$2);
    final depth = narrowDepth(frame.eyeOpen);
    for (final centre in layout.rings) {
      _paintRing(canvas, centre, layout, depth);
    }
  }

  void _paintRing(Canvas canvas, Offset centre, Mark1Layout layout, int depth) {
    final anyLit = depth < narrowDepthMax;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * layout.ringRadius / _ringRadius
      ..color = anyLit ? _eyeColour.withValues(alpha: 0.09) : _trackIdle;
    canvas.drawCircle(centre, layout.ringRadius, track);
    final glow = Paint()
      ..color = _eyeColour.withValues(alpha: 0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, layout.eyeLed * 0.75);
    final on = Paint()..color = _eyeColour;
    final off = Paint()..color = _eyeOff;
    for (var slot = 0; slot < ringSize; slot++) {
      final at = ringPixel(centre, layout.ringRadius, slot);
      if (pixelLit(slot, depth)) {
        canvas.drawCircle(at, layout.eyeLed, glow);
        canvas.drawCircle(at, layout.eyeLed, on);
      } else {
        canvas.drawCircle(at, layout.eyeLed, off);
      }
    }
  }

  void _paintPlate(Canvas canvas, Offset origin, double scale) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale, scale);
    final rim = svgPath('M82.19 0C124 0 164.38 3 164.38 28.69S124 57.37 82.19 57.37S0 54.37 0 28.69S40.4 0 82.19 0Z');
    final glass = svgPath('M82.19 2C123 2 162.38 5 162.38 28.69S123 55.37 82.19 55.37S2 52.37 2 28.69S41.4 2 82.19 2Z');
    canvas.drawPath(
      rim,
      Paint()..shader = Gradient.linear(Offset.zero, const Offset(0, _plateHeight), const [Color(0xFFFFFFFF), Color(0xFFA6B1BD)]),
    );
    canvas.drawPath(
      glass,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          const Offset(_plateWidth * 0.8, _plateHeight),
          const [Color(0xFF303940), Color(0xFF12191E), Color(0xFF263039)],
          const [0, 0.5, 1],
        ),
    );
    canvas.drawPath(
      svgPath('M15 10C47 2 115 2 148 11'),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = _reflection,
    );
    final grille = Paint()..color = _grille;
    for (var i = 0; i < _micDots; i++) {
      final angle = i * _goldenAngle;
      final r = _micRadius * math.sqrt((i + 0.5) / _micDots);
      canvas.drawCircle(_micCentre + Offset(math.cos(angle) * r, math.sin(angle) * r), _micDotRadius, grille);
    }
    canvas.restore();
  }
}

class Mark1Mouth implements MouthPainter {
  const Mark1Mouth();

  @override
  void paint(Canvas canvas, FaceFrame frame) {
    final layout = Mark1Layout.of(frame);
    final rows = mouthFrame(frame.mode, frame.viseme, frame.elapsed);
    final off = Paint()..color = _mouthOff;
    final on = Paint()..color = _mouthOn;
    final glow = Paint()
      ..color = _mouthGlow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, layout.mouthLed * 0.6);
    for (var y = 0; y < mouthRows; y++) {
      for (var x = 0; x < mouthCols; x++) {
        final at = layout.mouthOrigin + Offset(x * layout.pitch, y * layout.pitch);
        final lit = rows != null && (rows[y] >> x) & 1 == 1;
        if (lit) canvas.drawCircle(at, layout.mouthLed, glow);
        canvas.drawCircle(at, layout.mouthLed, lit ? on : off);
      }
    }
  }
}

/// The subset of SVG path syntax the faceplate uses: absolute M, C, S and Z.
Path svgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MCSZ]|-?[\d.]+').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  Offset current = Offset.zero, control = Offset.zero;
  Offset next() => Offset(double.parse(tokens[i++]), double.parse(tokens[i++]));
  while (i < tokens.length) {
    switch (tokens[i++]) {
      case 'M':
        current = next();
        control = current;
        path.moveTo(current.dx, current.dy);
      case 'C':
        final c1 = next(), c2 = next(), end = next();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        control = c2;
        current = end;
      case 'S':
        final c1 = current * 2 - control, c2 = next(), end = next();
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        control = c2;
        current = end;
      case 'Z':
        path.close();
    }
  }
  return path;
}
