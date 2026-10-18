/// The colourway a face paints in: the colour tokens every style reads from [FaceFrame.palette], so a new colourway is
/// a value and no new painting. The dark hardware greys are not a colourway; they stay fixed in [HardwareColours].
/// Pure; parsing never throws, and every bad name, key or hex string reports a fault and falls back to visage.
library;

import 'dart:ui';

import '../faults.dart';

/// The greys of the hardware a style draws: unlit LEDs, a lens housing and its blades, a matrix panel.
abstract final class HardwareColours {
  static const unlit = Color(0xFF12171C);
  static const housing = Color(0xFF1B1E24);
  static const blade = Color(0xFF262A31);
  static const panel = Color(0xFF0A0C10);
}

class FacePalette {
  const FacePalette({
    required this.eye,
    required this.eyeDim,
    required this.mouth,
    required this.accent,
    required this.led,
    required this.matrix,
    required this.matrixGlow,
  });

  /// The lit part of an eye.
  final Color eye;

  /// The unlit part of an eye, such as the lens ring under its arc.
  final Color eyeDim;

  /// Strokes and fills of a mouth, and highlights.
  final Color mouth;

  /// Listening, and the colour that stands out from the eyes.
  final Color accent;

  /// A lit Mark 1 ring LED.
  final Color led;

  /// A lit LED of a matrix mouth or eye.
  final Color matrix;

  /// The halo around a lit matrix mouth LED.
  final Color matrixGlow;

  static const visage = FacePalette(
    eye: Color(0xFFF5F5F5),
    eyeDim: Color(0xFF6D6D6D),
    mouth: Color(0xFFFFFFFF),
    accent: Color(0xFF1E9BFF),
    led: Color(0xFF70656A),
    matrix: Color(0xFFE1F3FF),
    matrixGlow: Color(0xFFADDEFB),
  );

  static const ember = FacePalette(
    eye: Color(0xFFFFB547),
    eyeDim: Color(0xFF5C3A12),
    mouth: Color(0xFFFFE2B8),
    accent: Color(0xFFFF5E1A),
    led: Color(0xFFC9862E),
    matrix: Color(0xFFFFD49A),
    matrixGlow: Color(0xFFFFB25C),
  );

  static const mint = FacePalette(
    eye: Color(0xFF8FF0C8),
    eyeDim: Color(0xFF2B5446),
    mouth: Color(0xFFDFFFF0),
    accent: Color(0xFFB28DFF),
    led: Color(0xFF4FA884),
    matrix: Color(0xFFC8FFE6),
    matrixGlow: Color(0xFF7FE8C0),
  );

  static const rose = FacePalette(
    eye: Color(0xFFFFA8C0),
    eyeDim: Color(0xFF5E3341),
    mouth: Color(0xFFFFE0EA),
    accent: Color(0xFF3FD3C6),
    led: Color(0xFFB06A80),
    matrix: Color(0xFFFFD6E3),
    matrixGlow: Color(0xFFF59AB8),
  );

  static const ice = FacePalette(
    eye: Color(0xFFCDEEFF),
    eyeDim: Color(0xFF3A5563),
    mouth: Color(0xFFF0FAFF),
    accent: Color(0xFF8C7BFF),
    led: Color(0xFF6E95AA),
    matrix: Color(0xFFD8F1FF),
    matrixGlow: Color(0xFF9CD6F5),
  );

  /// The Mark 1's LEDs on every token: the ring colour for eyes, the matrix colour for mouths.
  static const mark1 = FacePalette(
    eye: Color(0xFF70656A),
    eyeDim: Color(0xFF2E292B),
    mouth: Color(0xFFE1F3FF),
    accent: Color(0xFFADDEFB),
    led: Color(0xFF70656A),
    matrix: Color(0xFFE1F3FF),
    matrixGlow: Color(0xFFADDEFB),
  );

  /// A name, or an object of `#RRGGBB` / `#AARRGGBB` strings per token. A missing token is visage's, except that a
  /// missing `matrixGlow` follows a given `matrix`. Null is visage.
  factory FacePalette.parse(Object? value) {
    if (value == null) return visage;
    if (value is String) return _named(value);
    if (value is Map) return _fromTokens(value);
    reportFault('face colours $value', ArgumentError.value(value, 'colours', 'not a colourway name or an object'));
    return visage;
  }

  static FacePalette _named(String text) {
    final name = text.trim().toLowerCase();
    final found = facePalettes[name];
    if (found != null) return found;
    reportFault('face colours "$name"', ArgumentError.value(name, 'colours', 'not one of ${facePalettes.keys.join(', ')}'));
    return visage;
  }

  static FacePalette _fromTokens(Map<dynamic, dynamic> json) {
    for (final key in json.keys.where((k) => !paletteTokens.contains(k))) {
      reportFault('face colours key "$key"', ArgumentError.value(key, 'colours', 'not one of ${paletteTokens.join(', ')}'));
    }
    Color pick(String token, Color fallback) => json.containsKey(token) ? _hex(token, json[token], fallback) : fallback;
    final matrix = pick('matrix', visage.matrix);
    return FacePalette(
      eye: pick('eye', visage.eye),
      eyeDim: pick('eyeDim', visage.eyeDim),
      mouth: pick('mouth', visage.mouth),
      accent: pick('accent', visage.accent),
      led: pick('led', visage.led),
      matrix: matrix,
      matrixGlow: pick('matrixGlow', json.containsKey('matrix') ? matrix : visage.matrixGlow),
    );
  }

  static final _hexPattern = RegExp(r'^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$');

  static Color _hex(String token, Object? value, Color fallback) {
    final match = _hexPattern.firstMatch('${value ?? ''}'.trim());
    if (match == null) {
      reportFault('face colour $token "$value"', FormatException('not #RRGGBB or #AARRGGBB', value));
      return fallback;
    }
    final digits = match.group(1)!;
    return Color(int.parse(digits.length == 6 ? 'FF$digits' : digits, radix: 16));
  }

  Map<String, Color> get tokens => {
    'eye': eye,
    'eyeDim': eyeDim,
    'mouth': mouth,
    'accent': accent,
    'led': led,
    'matrix': matrix,
    'matrixGlow': matrixGlow,
  };

  Map<String, String> toJson() => tokens.map((token, colour) => MapEntry(token, hexOf(colour)));

  /// The colourway this palette is, if it is one.
  String? get name {
    for (final entry in facePalettes.entries) {
      if (entry.value == this) return entry.key;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is FacePalette &&
      other.eye == eye &&
      other.eyeDim == eyeDim &&
      other.mouth == mouth &&
      other.accent == accent &&
      other.led == led &&
      other.matrix == matrix &&
      other.matrixGlow == matrixGlow;

  @override
  int get hashCode => Object.hash(eye, eyeDim, mouth, accent, led, matrix, matrixGlow);

  @override
  String toString() => name ?? 'custom ${toJson()}';
}

const paletteTokens = ['eye', 'eyeDim', 'mouth', 'accent', 'led', 'matrix', 'matrixGlow'];

const facePalettes = <String, FacePalette>{
  'visage': FacePalette.visage,
  'ember': FacePalette.ember,
  'mint': FacePalette.mint,
  'rose': FacePalette.rose,
  'ice': FacePalette.ice,
  'mark1': FacePalette.mark1,
};

/// `#RRGGBB` for an opaque colour, `#AARRGGBB` otherwise.
String hexOf(Color colour) {
  final argb = colour.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  return '#${argb.startsWith('FF') ? argb.substring(2) : argb}';
}
