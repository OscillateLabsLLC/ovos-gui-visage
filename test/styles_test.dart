import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/composed_theme.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/face/styles.dart';
import 'package:ovos_gui_visage/face/visemes.dart';

import 'faults.dart';

/// Every eye style with every mouth style, on both backdrops, in every mode and in the badge, paints without a fault.
void main() {
  final frames = <FaceFrame>[
    for (final compact in [false, true])
      for (final mode in FaceMode.values)
        for (final viseme in [restCode, 0, 6])
          for (final eyeOpen in [1.0, 0.62, 0.08])
            FaceFrame(
              mode: mode,
              eyeOpen: eyeOpen,
              eyeScale: 1.1,
              lips: composedMouthShapes[viseme]!,
              viseme: viseme,
              elapsed: 0.37,
              compact: compact,
            ),
  ];

  for (final backdrop in backdrops.keys) {
    for (final eyes in eyeStyles.keys) {
      for (final mouth in mouthStyles.keys) {
        testWidgets('$eyes + $mouth on $backdrop paints every frame', (tester) async {
          final theme = FaceSpec(eyes: eyes, mouth: mouth, backdrop: backdrop, mouthSize: 'large').theme();
          final faults = await collectFaults(() async {
            for (final frame in frames) {
              await tester.pumpWidget(CustomPaint(size: const Size(frameWidth, frameHeight), painter: FacePainter(theme, frame)));
            }
          });
          expect(faults, isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  /// Every mode in and out of the badge, mid-speech, with the eyes open.
  for (final colours in facePalettes.keys.where((name) => name != 'visage')) {
    testWidgets('every pairing paints every frame in $colours', (tester) async {
      final faults = await collectFaults(() async {
        for (final backdrop in backdrops.keys) {
          for (final eyes in eyeStyles.keys) {
            for (final mouth in mouthStyles.keys) {
              final theme = FaceSpec(eyes: eyes, mouth: mouth, backdrop: backdrop, colours: facePalettes[colours]!).theme();
              for (final frame in frames.where((f) => f.eyeOpen == 1 && f.viseme == 0)) {
                final painted = frame.withPalette(theme.palette);
                await tester.pumpWidget(
                  CustomPaint(size: const Size(frameWidth, frameHeight), painter: FacePainter(theme, painted)),
                );
              }
            }
          }
        }
      });
      expect(faults, isEmpty);
      expect(tester.takeException(), isNull);
    });
  }

  test('every preset names real styles', () {
    for (final preset in facePresets.values) {
      expect(eyeStyles, contains(preset.eyes));
      expect(mouthStyles, contains(preset.mouth));
      expect(backdrops, contains(preset.backdrop));
    }
  });

  test('a large mouth grows the slot on the bare screen and not in the Mark 1 window', () {
    final big = FaceSpec.parse('lens+outline+large').theme();
    final regular = FaceSpec.parse('visage').theme();
    final frame = FaceFrame(mode: FaceMode.rest, eyeOpen: 1, eyeScale: 1, lips: composedMouthShapes[4]!, viseme: 4, elapsed: 0);
    expect(big.layoutFor(frame).mouth.width, closeTo(regular.layoutFor(frame).mouth.width * 1.4, 0.001));
    final plate = FaceSpec.parse('mark1+large').theme();
    expect(plate.layoutFor(frame).mouth.width, FaceSpec.parse('mark1').theme().layoutFor(frame).mouth.width);
  });
}
