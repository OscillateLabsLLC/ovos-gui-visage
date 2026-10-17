/// The motion of every animated icon layer, transcribed keyframe by keyframe from assets/icon_sources/ (the
/// stylesheets tool/split_icons.py strips). Keyed by icon name, then the layer's animated class and its ordinal
/// (1-based, document order) for `:nth-of-type` delays and directions; ordinal 0 covers every ordinal.
library;

import 'package:flutter/animation.dart';

import 'motion.dart';

const _ms = Duration(milliseconds: 1);

/// `@keyframes spin { to { rotate(360deg) } }`, 20 s linear.
const _spin = {
  Prop.rotate: [(0.0, 0.0), (1.0, 360.0)],
};

Map<Prop, Track> _driftTracks(double from, double to) => {
  Prop.dx: [(0.0, from), (1.0, to)],
};

/// `@keyframes fall { from { translate(1px, -4px); opacity 0 } 30% { opacity 1 } to { translate(-2px, 6px); opacity 0 } }`
const _fall = {
  Prop.dx: [(0.0, 1.0), (1.0, -2.0)],
  Prop.dy: [(0.0, -4.0), (1.0, 6.0)],
  Prop.opacity: [(0.0, 0.0), (0.3, 1.0), (1.0, 0.0)],
};

/// `@keyframes flutter { from { translate(0, -5px); opacity 0 } 25% { opacity 1 } 50% { translate(2px, 1px) } to { translate(-1px, 7px); opacity 0 } }`
const _flutter = {
  Prop.dx: [(0.0, 0.0), (0.5, 2.0), (1.0, -1.0)],
  Prop.dy: [(0.0, -5.0), (0.5, 1.0), (1.0, 7.0)],
  Prop.opacity: [(0.0, 0.0), (0.25, 1.0), (1.0, 0.0)],
};

/// `@keyframes flash { 0%, 70%, 100% { opacity 1 } 74% { 0.2 } 78% { 1 } 82% { 0.4 } }`
const _flash = {
  Prop.opacity: [(0.0, 1.0), (0.7, 1.0), (0.74, 0.2), (0.78, 1.0), (0.82, 0.4), (1.0, 1.0)],
};

/// `@keyframes twinkle { 0%, 100% { opacity 1 } 50% { opacity 0.25 } }`
const _twinkle = {
  Prop.opacity: [(0.0, 1.0), (0.5, 0.25), (1.0, 1.0)],
};

/// `@keyframes swing { 0%, 70%, 100% { 0deg } 76% { 14deg } 84% { -11deg } 91% { 6deg } 96% { -3deg } }`
const swing = {
  Prop.rotate: [(0.0, 0.0), (0.7, 0.0), (0.76, 14.0), (0.84, -11.0), (0.91, 6.0), (0.96, -3.0), (1.0, 0.0)],
};

/// `@keyframes wave { 0% { scale(0.55); opacity 0.9 } 100% { scale(1.35); opacity 0 } }`
const _wave = {
  Prop.scale: [(0.0, 0.55), (1.0, 1.35)],
  Prop.opacity: [(0.0, 0.9), (1.0, 0.0)],
};

Motion _drift(Duration period, {bool reverse = false, double from = -3, double to = 3}) => Motion(
  tracks: _driftTracks(from, to),
  period: period,
  curve: Curves.easeInOut,
  direction: reverse ? Direction.alternateReverse : Direction.alternate,
);

Motion _fallAt(Duration delay) => Motion(tracks: _fall, period: _ms * 1100, delay: delay);

Motion _flutterAt(Duration delay) =>
    Motion(tracks: _flutter, period: const Duration(seconds: 3), curve: Curves.easeInOut, delay: delay);

Motion _swingAt({required double pivotY, Duration delay = Duration.zero}) =>
    Motion(tracks: swing, period: _ms * 3200, curve: Curves.easeInOut, delay: delay, pivotX: 32, pivotY: pivotY);

/// `.wave { transform-origin: 32px 26px }`.
Motion _waveAt(Duration delay) => Motion(tracks: _wave, period: _ms * 2400, curve: Curves.easeOut, delay: delay, pivotY: 26);

/// icon -> animated class -> ordinal -> motion.
final iconMotion = <String, Map<String, Map<int, Motion>>>{
  // `.rays { transform-box: fill-box; transform-origin: center }`: the pivot is the centre of the rays' own box.
  'sun': {
    'rays': {0: const Motion(tracks: _spin, period: Duration(seconds: 20))},
  },
  'partial_clouds': {
    'rays': {0: const Motion(tracks: _spin, period: Duration(seconds: 20), pivotX: 22, pivotY: 22)},
    'cloud': {0: _drift(const Duration(seconds: 7), from: -2, to: 3)},
  },
  'clouds': {
    'back': {0: _drift(const Duration(seconds: 9), reverse: true)},
    'front': {0: _drift(const Duration(seconds: 7))},
  },
  // `.band:nth-of-type(2n) { animation-direction: alternate-reverse }`
  'fog': {
    'band': {
      1: _drift(const Duration(seconds: 6)),
      2: _drift(const Duration(seconds: 6), reverse: true),
      3: _drift(const Duration(seconds: 6)),
      4: _drift(const Duration(seconds: 6), reverse: true),
    },
  },
  'rain': {
    'drop': {1: _fallAt(Duration.zero), 2: _fallAt(_ms * -400), 3: _fallAt(_ms * -750)},
  },
  'snow': {
    'flake': {
      1: _flutterAt(Duration.zero),
      2: _flutterAt(const Duration(seconds: -1)),
      3: _flutterAt(const Duration(seconds: -2)),
    },
  },
  'storm': {
    'bolt': {0: const Motion(tracks: _flash, period: Duration(seconds: 4), curve: Curves.easeOut)},
  },
  'night': {
    'star': {
      1: const Motion(tracks: _twinkle, period: Duration(seconds: 3), curve: Curves.easeInOut),
      2: Motion(tracks: _twinkle, period: const Duration(seconds: 3), curve: Curves.easeInOut, delay: _ms * -1500),
    },
  },
  // `.bell { transform-origin: 32px 9px } .clapper { transform-origin: 32px 12px; animation-delay: -0.25s }`
  'bell': {
    'bell': {0: _swingAt(pivotY: 9)},
    'clapper': {0: _swingAt(pivotY: 12, delay: _ms * -250)},
  },
  'mic': {
    'wave': {1: _waveAt(Duration.zero), 2: _waveAt(_ms * 800), 3: _waveAt(_ms * 1600)},
  },
};

/// A ringing bell swings 14 degrees either way every 0.45 s instead of its rest swing (alerts.css bell-shake).
const bellShake = Motion(
  tracks: {
    Prop.rotate: [(0.0, 0.0), (0.25, -14.0), (0.75, 14.0), (1.0, 0.0)],
  },
  period: Duration(milliseconds: 450),
  curve: Curves.easeInOut,
  pivotX: 32,
  pivotY: 9,
);

Motion? motionFor(String icon, String? cls, int nth) {
  if (cls == null) return null;
  final byClass = iconMotion[icon]?[cls];
  return byClass?[nth] ?? byClass?[0];
}
