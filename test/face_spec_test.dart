import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';

import 'faults.dart';

void main() {
  test('a preset name, eyes+mouth tokens in any order, or an object', () {
    expect(FaceSpec.parse('mark1'), const FaceSpec(eyes: 'ring', mouth: 'matrix', backdrop: 'mark1'));
    expect(FaceSpec.parse(' Visor+Waveform '), const FaceSpec(eyes: 'visor', mouth: 'waveform'));
    expect(FaceSpec.parse('large+bars+dot'), const FaceSpec(eyes: 'dot', mouth: 'bars', mouthSize: 'large'));
    expect(FaceSpec.parse({'eyes': 'block', 'mouthSize': 'large'}), const FaceSpec(eyes: 'block', mouthSize: 'large'));
    expect(FaceSpec.parse(null), FaceSpec.visage);
    expect(FaceSpec.parse(42), FaceSpec.visage);
  });

  test('an unknown token reports once and leaves the rest', () async {
    late FaceSpec spec;
    final faults = await collectFaults(() async => spec = FaceSpec.parse('oval+teeth'));
    expect(faults, hasLength(1));
    expect(spec, const FaceSpec(eyes: 'oval'));
  });

  test('merging takes the fields present, and a preset resets the pairing first', () {
    const current = FaceSpec(eyes: 'pixel', mouth: 'orb', mouthSize: 'large');
    expect(current.merge({'mouth': 'bars'}), const FaceSpec(eyes: 'pixel', mouth: 'bars', mouthSize: 'large'));
    expect(current.merge({'preset': 'robot'}), const FaceSpec(eyes: 'block', mouth: 'solid', mouthSize: 'large'));
    expect(current.merge({'preset': 'robot', 'eyes': 'dot'}), const FaceSpec(eyes: 'dot', mouth: 'solid', mouthSize: 'large'));
  });

  test('the preset name is found back from the pairing, and the JSON round-trips', () {
    expect(FaceSpec.parse('camera').presetName, 'camera');
    expect(const FaceSpec(eyes: 'mono', mouth: 'bars').presetName, isNull);
    final spec = FaceSpec.parse('orbit+large');
    expect(FaceSpec.parse(spec.toJson()), spec);
    expect(spec.toString(), 'mono+orb+large');
  });

  test('an unknown style in a spec reports and the theme falls back for that part', () async {
    late var theme = FaceSpec.visage.theme();
    final faults = await collectFaults(() async => theme = const FaceSpec(mouth: 'teeth').theme());
    expect(faults, hasLength(1));
    expect(theme.mouthStyle.runtimeType, FaceSpec.visage.theme().mouthStyle.runtimeType);
  });
}
