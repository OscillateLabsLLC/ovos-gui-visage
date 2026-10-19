import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';

import 'faults.dart';

void main() {
  test('a preset name, eyes+mouth tokens in any order, or an object', () {
    expect(FaceSpec.parse('mark1'), const FaceSpec(eyes: 'ring', mouth: 'matrix', backdrop: 'mark1', colours: FacePalette.mark1));
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

  test('a colourway is a token, a later preset resets it, and the theme paints in it', () {
    expect(FaceSpec.parse('pod+ember').colours, FacePalette.ember);
    expect(FaceSpec.parse('ember+pod').colours, FacePalette.visage);
    expect(FaceSpec.parse('mint+large').theme().palette, FacePalette.mint);
    expect(FaceSpec.parse('mark1').presetName, 'mark1');
    expect(FaceSpec.parse('mark1+rose').presetName, 'mark1');
  });

  test('colours merge by name or object, and a preset brings its own', () {
    const current = FaceSpec(eyes: 'dot', colours: FacePalette.ice);
    expect(current.merge({'eyes': 'oval'}).colours, FacePalette.ice);
    expect(current.merge({'colours': 'rose'}).colours, FacePalette.rose);
    expect(
      current
          .merge({
            'colours': {'eye': '#102030'},
          })
          .colours
          .eye,
      const Color(0xFF102030),
    );
    expect(current.merge({'preset': 'mark1'}).colours, FacePalette.mark1);
    expect(current.merge({'preset': 'robot'}).colours, FacePalette.visage);
    expect(current.merge({'preset': 'robot', 'colours': 'ember'}).colours, FacePalette.ember);
  });

  test('the colourway goes to JSON by name when it has one, else as tokens, and round-trips', () {
    expect(FaceSpec.parse('camera+rose').toJson()['colours'], 'rose');
    final custom = FaceSpec.visage.merge({
      'colours': {'accent': '#FF00FF'},
    });
    expect(custom.toJson()['colours'], isA<Map<String, String>>());
    expect(FaceSpec.parse(custom.toJson()), custom);
    expect(FaceSpec.parse(FaceSpec.parse('led+ice').toJson()), FaceSpec.parse('led+ice'));
    expect(FaceSpec.parse('pod+ember').toString(), 'oval+none+regular+ember');
  });

  test('the log name leaves out the colourway the preset brings and names any other', () {
    expect(FaceSpec.parse('mark1').toString(), 'ring+matrix+regular+mark1');
    expect(FaceSpec.parse('mark1+rose').toString(), 'ring+matrix+regular+mark1+rose');
    expect(FaceSpec.parse('mark1').copyWith(colours: FacePalette.visage).toString(), 'ring+matrix+regular+mark1+visage');
    expect(FaceSpec.parse('retro+rose').toString(), 'ring+waveform+regular+rose');
    expect(FaceSpec.parse('retro').toString(), 'ring+waveform+regular');
  });

  test('an unknown colourway in an object reports and falls back to visage', () async {
    late FaceSpec spec;
    final faults = await collectFaults(() async => spec = FaceSpec.parse({'eyes': 'ring', 'colours': 'teal'}));
    expect(faults, hasLength(1));
    expect(spec, const FaceSpec(eyes: 'ring'));
  });
}
