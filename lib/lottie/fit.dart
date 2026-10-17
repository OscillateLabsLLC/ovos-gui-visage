/// Where a Lottie's main ring is, read from its JSON, so the drawn ring can be sized to a chip's ring instead of the
/// composition box (OVOS's loading.json is a 307x389 canvas whose ring is 222 wide). Port of lottie_fit.js. Pure.
library;

import 'dart:math' as math;

/// The chip ring from circle.dart Ring: r 46 plus half a stroke of 6, in a 100-unit box, so its outer edge is 0.98.
const chipRingFill = 0.98;

typedef Ring = ({double cx, double cy, double r});

List<double>? _fixed(dynamic prop) {
  final k = prop is Map ? prop['k'] : null;
  if (k is List && k.isNotEmpty && k.first is num) return [for (final v in k) (v as num).toDouble()];
  return null;
}

double _number(dynamic prop, double fallback) {
  final k = prop is Map ? prop['k'] : null;
  return k is num ? k.toDouble() : fallback;
}

List<double> _rotate(List<double> p, double degrees) {
  final rad = degrees * math.pi / 180;
  return [p[0] * math.cos(rad) - p[1] * math.sin(rad), p[0] * math.sin(rad) + p[1] * math.cos(rad)];
}

/// Circles in one shape layer, in composition coordinates; skips anything animated that would move them.
List<Ring> _layerRings(Map layer) {
  final ks = layer['ks'] as Map?;
  final p = _fixed(ks?['p']), a = _fixed(ks?['a']), s = _fixed(ks?['s']);
  if (p == null || a == null || s == null || s[0] != s[1]) return [];
  final scale = s[0] / 100;
  final rings = <Ring>[];
  for (final group in (layer['shapes'] as List? ?? const [])) {
    if (group is! Map || group['ty'] != 'gr') continue;
    final items = (group['it'] as List? ?? const []).whereType<Map>();
    Map? find(String ty) => items.cast<Map?>().firstWhere((item) => item!['ty'] == ty, orElse: () => null);
    final el = find('el');
    final size = _fixed(el?['s']);
    if (size == null || size[0] != size[1]) continue;
    final at = [
      _fixed(el!['p']) ?? [0, 0],
      _fixed(find('tr')?['p']) ?? [0, 0],
    ];
    final offset = [at[0][0] + at[1][0] - a[0], at[0][1] + at[1][1] - a[1]];
    final moved = offset[0] != 0 || offset[1] != 0;
    if (moved && (ks?['r'] is! Map || (ks!['r'] as Map)['k'] is! num)) continue;
    final d = _rotate(offset, _number(ks?['r'], 0));
    final r = (size[0] / 2 + _number(find('st')?['w'], 0) / 2) * scale;
    rings.add((cx: p[0] + d[0] * scale, cy: p[1] + d[1] * scale, r: r));
  }
  return rings;
}

/// The largest static circle in the animation, or null when it has none.
Ring? ringOf(Map<String, dynamic> data) {
  Ring? best;
  for (final layer in (data['layers'] as List? ?? const []).whereType<Map>()) {
    for (final ring in _layerRings(layer)) {
      if (best == null || ring.r > best.r) best = ring;
    }
  }
  return best;
}

/// Placement of the animation, as fractions of the chip, that puts its ring's outer edge on the chip ring.
({double width, double height, double left, double top})? ringFit(Map<String, dynamic> data, {double fill = chipRingFill}) {
  final ring = ringOf(data);
  if (ring == null) return null;
  final k = fill / 2 / ring.r;
  return (width: (data['w'] as num) * k, height: (data['h'] as num) * k, left: 0.5 - ring.cx * k, top: 0.5 - ring.cy * k);
}
