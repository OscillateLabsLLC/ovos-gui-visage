/// A small CSS-keyframes engine. As in CSS, every property has its own track: it interpolates between the
/// keyframes that mention it, with the timing curve applied per interval, so a keyframe that sets only opacity
/// leaves the transform on its own course. A delay shifts the cycle (negative = started that much earlier, which
/// the icons use for phase offsets) and the direction may bounce. Pure.
library;

import 'package:flutter/animation.dart';

enum Direction { normal, alternate, alternateReverse }

enum Prop { dx, dy, rotate, scale, opacity }

/// One evaluated frame: translation in viewBox units, rotation in degrees, uniform scale, opacity.
class Frame {
  const Frame({this.dx = 0, this.dy = 0, this.rotate = 0, this.scale = 1, this.opacity = 1});

  final double dx, dy, rotate, scale, opacity;

  @override
  bool operator ==(Object other) =>
      other is Frame &&
      other.dx == dx &&
      other.dy == dy &&
      other.rotate == rotate &&
      other.scale == scale &&
      other.opacity == opacity;

  @override
  int get hashCode => Object.hash(dx, dy, rotate, scale, opacity);

  @override
  String toString() => 'Frame(dx: $dx, dy: $dy, rotate: $rotate, scale: $scale, opacity: $opacity)';
}

/// A property's keyframes: (cycle fraction 0..1, value), ascending.
typedef Track = List<(double, double)>;

const _defaults = {Prop.dx: 0.0, Prop.dy: 0.0, Prop.rotate: 0.0, Prop.scale: 1.0, Prop.opacity: 1.0};

class Motion {
  const Motion({
    required this.tracks,
    required this.period,
    this.curve = Curves.linear,
    this.delay = Duration.zero,
    this.direction = Direction.normal,
    this.pivotX = 32,
    this.pivotY = 32,
  });

  final Map<Prop, Track> tracks;
  final Duration period;
  final Curve curve;
  final Duration delay;
  final Direction direction;

  /// transform-origin, in viewBox units.
  final double pivotX, pivotY;

  /// Where in the cycle (0..1) the animation is at [elapsed] since the icon appeared.
  double phase(Duration elapsed) {
    final cycles = (elapsed - delay).inMicroseconds / period.inMicroseconds;
    if (cycles < 0) return direction == Direction.alternateReverse ? 1 : 0;
    if (direction == Direction.normal) return cycles % 1;
    final half = cycles % 2;
    final forward = (half < 1) != (direction == Direction.alternateReverse);
    return forward ? half % 1 : 1 - half % 1;
  }

  Frame at(Duration elapsed) => frameAt(phase(elapsed));

  Frame frameAt(double p) => Frame(
    dx: value(Prop.dx, p),
    dy: value(Prop.dy, p),
    rotate: value(Prop.rotate, p),
    scale: value(Prop.scale, p),
    opacity: value(Prop.opacity, p),
  );

  /// The property at cycle fraction [p]; outside its keyframes a track holds its nearest value, as CSS fills in.
  double value(Prop prop, double p) {
    final track = tracks[prop];
    if (track == null || track.isEmpty) return _defaults[prop]!;
    if (p <= track.first.$1) return track.first.$2;
    for (var i = 1; i < track.length; i++) {
      final (t0, a) = track[i - 1];
      final (t1, b) = track[i];
      if (p <= t1) return t1 == t0 ? b : a + (b - a) * curve.transform((p - t0) / (t1 - t0));
    }
    return track.last.$2;
  }
}
