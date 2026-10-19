/// What a configured face is: an eye style, a mouth style, a mouth size and a backdrop, by name, and a colourway. Pure; parsing never
/// throws, and [theme] reports every unknown name once and falls back to the visage part for it.
library;

import '../faults.dart';
import 'composed_theme.dart';
import 'face_palette.dart';
import 'styles.dart';

const defaultEyes = 'lens';
const defaultMouth = 'outline';
const defaultMouthSize = 'regular';
const defaultBackdrop = 'none';

class FaceSpec {
  const FaceSpec({
    this.eyes = defaultEyes,
    this.mouth = defaultMouth,
    this.mouthSize = defaultMouthSize,
    this.backdrop = defaultBackdrop,
    this.colours = FacePalette.visage,
  });

  final String eyes;
  final String mouth;
  final String mouthSize;
  final String backdrop;
  final FacePalette colours;

  static const visage = FaceSpec();

  /// `+`-separated tokens, each a preset, eye style, mouth style, mouth size, backdrop or colourway name, later tokens
  /// winning; or an object with `eyes`, `mouth`, `mouthSize`, `backdrop` and `colours` (a colourway name or an object
  /// of tokens, face_palette.dart). Null or anything else is the visage face.
  factory FaceSpec.parse(Object? value) {
    if (value is Map) return visage.merge(value);
    if (value is! String) return visage;
    final text = value.trim().toLowerCase();
    var spec = visage;
    for (final token in text.split('+').map((t) => t.trim()).where((t) => t.isNotEmpty)) {
      spec = spec._withToken(token);
    }
    return spec;
  }

  factory FaceSpec.ofPreset(FacePreset preset) =>
      FaceSpec(eyes: preset.eyes, mouth: preset.mouth, backdrop: preset.backdrop, colours: preset.colours);

  /// The fields present in [json] over this spec; a `preset` field resets everything but the mouth size first, the
  /// colourway to the preset's own.
  FaceSpec merge(Map<dynamic, dynamic> json) {
    var base = this;
    final preset = facePresets[json['preset']?.toString().toLowerCase()];
    if (preset != null) base = FaceSpec.ofPreset(preset).copyWith(mouthSize: mouthSize);
    String pick(String key, String current) => (json[key]?.toString() ?? current).trim().toLowerCase();
    return FaceSpec(
      eyes: pick('eyes', base.eyes),
      mouth: pick('mouth', base.mouth),
      mouthSize: pick('mouthSize', base.mouthSize),
      backdrop: pick('backdrop', base.backdrop),
      colours: json.containsKey('colours') ? FacePalette.parse(json['colours']) : base.colours,
    );
  }

  FaceSpec _withToken(String token) {
    final preset = facePresets[token];
    if (preset != null) return FaceSpec.ofPreset(preset).copyWith(mouthSize: mouthSize);
    if (eyeStyles.containsKey(token)) return copyWith(eyes: token);
    if (mouthStyles.containsKey(token)) return copyWith(mouth: token);
    if (mouthSizes.containsKey(token)) return copyWith(mouthSize: token);
    if (backdrops.containsKey(token)) return copyWith(backdrop: token);
    if (facePalettes.containsKey(token)) return copyWith(colours: facePalettes[token]);
    reportFault('face "$token"', ArgumentError.value(token, 'face', 'not a style, size, backdrop, colourway or preset name'));
    return this;
  }

  FaceSpec copyWith({String? eyes, String? mouth, String? mouthSize, String? backdrop, FacePalette? colours}) => FaceSpec(
    eyes: eyes ?? this.eyes,
    mouth: mouth ?? this.mouth,
    mouthSize: mouthSize ?? this.mouthSize,
    backdrop: backdrop ?? this.backdrop,
    colours: colours ?? this.colours,
  );

  /// The preset this spec is, if it is one (mouth size and colourway aside).
  String? get presetName {
    for (final entry in facePresets.entries) {
      final p = entry.value;
      if (p.eyes == eyes && p.mouth == mouth && p.backdrop == backdrop) return entry.key;
    }
    return null;
  }

  /// The colourway by name when it is a named one, else its tokens.
  Map<String, dynamic> toJson() => {
    'eyes': eyes,
    'mouth': mouth,
    'mouthSize': mouthSize,
    'backdrop': backdrop,
    'colours': colours.name ?? colours.toJson(),
  };

  ComposedTheme theme() => ComposedTheme(
    backdrop: _lookup(backdrops, backdrop, 'backdrop', defaultBackdrop),
    eyeStyle: _lookup(eyeStyles, eyes, 'eyes', defaultEyes),
    mouthStyle: _lookup(mouthStyles, mouth, 'mouth', defaultMouth),
    mouthScale: _lookup(mouthSizes, mouthSize, 'mouth size', defaultMouthSize),
    palette: colours,
  );

  static T _lookup<T>(Map<String, T> table, String name, String what, String fallback) {
    final found = table[name];
    if (found != null) return found;
    reportFault('face $what "$name"', ArgumentError.value(name, what, 'not one of ${table.keys.join(', ')}'));
    return table[fallback]!;
  }

  @override
  bool operator ==(Object other) =>
      other is FaceSpec &&
      other.eyes == eyes &&
      other.mouth == mouth &&
      other.mouthSize == mouthSize &&
      other.backdrop == backdrop &&
      other.colours == colours;

  @override
  int get hashCode => Object.hash(eyes, mouth, mouthSize, backdrop, colours);

  /// The colourway is left out when it is the one the spec's preset brings, or visage when it is no preset.
  @override
  String toString() {
    final implied = facePresets[presetName]?.colours ?? FacePalette.visage;
    return '$eyes+$mouth+$mouthSize${backdrop == defaultBackdrop ? '' : '+$backdrop'}'
        '${colours == implied ? '' : '+${colours.name ?? 'custom colours'}'}';
  }
}
