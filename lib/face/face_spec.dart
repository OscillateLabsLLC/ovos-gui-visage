/// What a configured face is: an eye style, a mouth style, a mouth size and a backdrop, by name. Pure; parsing never
/// throws, and [theme] reports every unknown name once and falls back to the visage part for it.
library;

import '../faults.dart';
import 'composed_theme.dart';
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
  });

  final String eyes;
  final String mouth;
  final String mouthSize;
  final String backdrop;

  static const visage = FaceSpec();

  /// `+`-separated tokens in any order, each a preset, eye style, mouth style, mouth size or backdrop name, or an
  /// object with `eyes`, `mouth`, `mouthSize` and `backdrop`. Null or anything else is the visage face.
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

  factory FaceSpec.ofPreset(FacePreset preset) => FaceSpec(eyes: preset.eyes, mouth: preset.mouth, backdrop: preset.backdrop);

  /// The fields present in [json] over this spec; a `preset` field resets everything else first.
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
    );
  }

  FaceSpec _withToken(String token) {
    final preset = facePresets[token];
    if (preset != null) return copyWith(eyes: preset.eyes, mouth: preset.mouth, backdrop: preset.backdrop);
    if (eyeStyles.containsKey(token)) return copyWith(eyes: token);
    if (mouthStyles.containsKey(token)) return copyWith(mouth: token);
    if (mouthSizes.containsKey(token)) return copyWith(mouthSize: token);
    if (backdrops.containsKey(token)) return copyWith(backdrop: token);
    reportFault('face "$token"', ArgumentError.value(token, 'face', 'not a style, size, backdrop or preset name'));
    return this;
  }

  FaceSpec copyWith({String? eyes, String? mouth, String? mouthSize, String? backdrop}) => FaceSpec(
    eyes: eyes ?? this.eyes,
    mouth: mouth ?? this.mouth,
    mouthSize: mouthSize ?? this.mouthSize,
    backdrop: backdrop ?? this.backdrop,
  );

  /// The preset this spec is, if it is one (mouth size aside).
  String? get presetName {
    for (final entry in facePresets.entries) {
      final p = entry.value;
      if (p.eyes == eyes && p.mouth == mouth && p.backdrop == backdrop) return entry.key;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {'eyes': eyes, 'mouth': mouth, 'mouthSize': mouthSize, 'backdrop': backdrop};

  ComposedTheme theme() => ComposedTheme(
    backdrop: _lookup(backdrops, backdrop, 'backdrop', defaultBackdrop),
    eyeStyle: _lookup(eyeStyles, eyes, 'eyes', defaultEyes),
    mouthStyle: _lookup(mouthStyles, mouth, 'mouth', defaultMouth),
    mouthScale: _lookup(mouthSizes, mouthSize, 'mouth size', defaultMouthSize),
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
      other.backdrop == backdrop;

  @override
  int get hashCode => Object.hash(eyes, mouth, mouthSize, backdrop);

  @override
  String toString() => '$eyes+$mouth+$mouthSize${backdrop == defaultBackdrop ? '' : '+$backdrop'}';
}
