/// Mycroft viseme codes 0-6 as mouth outlines, the viseme timeline, and shape tweening (port of visemes.js). Pure.
///
/// Codes come from ovos_utils/lang/visimes.py (phoneme -> code); shapes redraw the Mark 1 firmware MOUTH_VISEMES
/// bitmaps smooth. Every shape has the same point count so any two can be interpolated point by point. Shapes are in
/// a 200 x 100 local box centred on (100, 50); the face theme scales them onto the screen.
library;

import 'dart:math' as math;
import 'dart:ui';

const restCode = 4;
const lipPoints = 9;
const mouthCx = 100.0;
const mouthCy = 50.0;

/// w: half width; up/down: lip opening at the centre; round: 1 = parabola, < 1 = squarer; smile: corner lift.
class MouthShape {
  const MouthShape({required this.w, required this.up, required this.down, required this.round, required this.smile});

  final double w, up, down, round, smile;

  MouthShape scaled(double k) => MouthShape(w: w * k, up: up * k, down: down * k, round: round, smile: smile);
}

const mouthShapeSpecs = <int, MouthShape>{
  0: MouthShape(w: 46, up: 5, down: 30, round: 0.6, smile: 4), // ae ah iy ay hh: wide open, flat top
  1: MouthShape(w: 18, up: 20, down: 20, round: 0.5, smile: 0), // aw: small tall oval
  2: MouthShape(w: 22, up: 17, down: 17, round: 0.35, smile: 0), // uh w r ow er: rounded O
  3: MouthShape(w: 34, up: 4, down: 20, round: 0.7, smile: 3), // th s sh n t d l k g: half open
  4: MouthShape(w: 56, up: 0, down: 0, round: 1, smile: 7), // b p m, pause: closed smile
  5: MouthShape(w: 34, up: 11, down: 11, round: 0.4, smile: 2), // f v: narrow lens
  6: MouthShape(w: 16, up: 14, down: 14, round: 0.5, smile: 0), // oy ao: tiny round
};

double _lipY(MouthShape shape, double x, double opening, double sign) {
  final u = x.abs() / shape.w;
  final bulge = math.pow(math.max(0, 1 - u * u), shape.round).toDouble();
  return mouthCy + sign * opening * bulge - shape.smile * u * u;
}

/// The closed outline of one viseme; openScale shrinks or grows every open shape, the rest smile keeps its width.
List<Offset> shapePoints(int code, {double openScale = 1}) {
  final base = mouthShapeSpecs[code] ?? mouthShapeSpecs[restCode]!;
  final shape = code == restCode || !mouthShapeSpecs.containsKey(code) ? base : base.scaled(openScale);
  // Cosine spacing samples the steep ends of each lip densely, so hollow outlines stay smooth at the corners.
  final xs = [for (var i = 0; i < lipPoints; i++) -shape.w * math.cos(math.pi * i / (lipPoints - 1))];
  final upper = [for (final x in xs) Offset(mouthCx + x, _lipY(shape, x, shape.up, -1))];
  final lower = [for (final x in xs.sublist(1, xs.length - 1).reversed) Offset(mouthCx + x, _lipY(shape, x, shape.down, 1))];
  return [...upper, ...lower];
}

Map<int, List<Offset>> mouthShapes({double openScale = 1}) => {
  for (final code in mouthShapeSpecs.keys) code: shapePoints(code, openScale: openScale),
};

List<Offset> lerpPoints(List<Offset> from, List<Offset> to, double k) => [
  for (var i = 0; i < from.length; i++) from[i] + (to[i] - from[i]) * k,
];

/// Closed Catmull-Rom spline through the points, as cubic Beziers.
Path toPath(List<Offset> points) {
  final n = points.length;
  Offset at(int i) => points[(i + n) % n];
  final path = Path()..moveTo(points[0].dx, points[0].dy);
  for (var i = 0; i < n; i++) {
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
  }
  return path..close();
}

/// The viseme code at `t` seconds after speech start, or null after the list ends. Pairs are [code, cumulative end
/// time] (ovos_bus_client EnclosureApi.mouth_viseme; audio-out.md §5.4 `ovos.audio.output.visemes`, the same shape with
/// string codes): code k is shown from the previous end until its own end. A code outside the set is the rest shape, as
/// §5.4 asks.
int? visemeAt(List<dynamic> visemes, double t) {
  if (t < 0) return null;
  for (final pair in visemes) {
    final end = double.parse(pair[1].toString());
    if (t < end) return _knownCode(int.tryParse(pair[0].toString()));
  }
  return null;
}

int _knownCode(int? code) => mouthShapeSpecs.containsKey(code) ? code! : restCode;
