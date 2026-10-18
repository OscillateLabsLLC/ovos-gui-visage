import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';

import 'faults.dart';

void main() {
  test('visage is the colours the face shipped with', () {
    expect(FacePalette.visage.eye, const Color(0xFFF5F5F5));
    expect(FacePalette.visage.accent, const Color(0xFF1E9BFF));
    expect(FacePalette.visage.led, const Color(0xFF70656A));
    expect(FacePalette.visage.matrix, const Color(0xFFE1F3FF));
    expect(FacePalette.parse(null), FacePalette.visage);
  });

  test('a name in any case is the colourway, and the name is found back', () {
    expect(FacePalette.parse(' Ember '), FacePalette.ember);
    for (final entry in facePalettes.entries) {
      expect(entry.value.name, entry.key);
    }
    expect(
      const FacePalette(
        eye: Color(0xFF000001),
        eyeDim: Color(0xFF000001),
        mouth: Color(0xFF000001),
        accent: Color(0xFF000001),
        led: Color(0xFF000001),
        matrix: Color(0xFF000001),
        matrixGlow: Color(0xFF000001),
      ).name,
      isNull,
    );
  });

  test('every colourway keeps its accent apart from its eyes', () {
    for (final palette in facePalettes.values) {
      final eye = palette.eye, accent = palette.accent;
      final distance = (eye.r - accent.r).abs() + (eye.g - accent.g).abs() + (eye.b - accent.b).abs();
      expect(distance, greaterThan(0.4), reason: '${palette.name}');
    }
  });

  test('an object takes #RRGGBB and #AARRGGBB per token, visage for the rest', () {
    final palette = FacePalette.parse({'eye': '#FFB547', 'accent': '80ff5e1a'});
    expect(palette.eye, const Color(0xFFFFB547));
    expect(palette.accent, const Color(0x80FF5E1A));
    expect(palette.mouth, FacePalette.visage.mouth);
    expect(palette.matrixGlow, FacePalette.visage.matrixGlow);
  });

  test('a given matrix colour carries the glow unless the glow is given', () {
    expect(FacePalette.parse({'matrix': '#FF0000'}).matrixGlow, const Color(0xFFFF0000));
    expect(FacePalette.parse({'matrix': '#FF0000', 'matrixGlow': '#00FF00'}).matrixGlow, const Color(0xFF00FF00));
  });

  test('a bad hex, an unknown key, an unknown name and a wrong type each report and fall back', () async {
    late FacePalette badHex, badKey, badName, badType;
    final faults = await collectFaults(() async {
      badHex = FacePalette.parse({'eye': '#12345', 'accent': '#FF5E1A'});
      badKey = FacePalette.parse({'eyes': '#FFFFFF'});
      badName = FacePalette.parse('teal');
      badType = FacePalette.parse(42);
    });
    expect(faults, hasLength(4));
    expect(badHex.eye, FacePalette.visage.eye);
    expect(badHex.accent, const Color(0xFFFF5E1A));
    expect(badKey, FacePalette.visage);
    expect(badName, FacePalette.visage);
    expect(badType, FacePalette.visage);
  });

  test('the JSON is hex per token and round-trips', () {
    final json = FacePalette.ember.toJson();
    expect(json['eye'], '#FFB547');
    expect(json.keys, paletteTokens);
    expect(FacePalette.parse(json), FacePalette.ember);
    final translucent = FacePalette.parse({'accent': '#80FF5E1A'});
    expect(translucent.toJson()['accent'], '#80FF5E1A');
    expect(FacePalette.parse(translucent.toJson()), translucent);
  });
}
