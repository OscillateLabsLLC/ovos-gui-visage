import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/face/mark1_images.g.dart';
import 'package:ovos_gui_visage/face/mark1_theme.dart';
import 'package:ovos_gui_visage/face/composed_theme.dart';
import 'package:ovos_gui_visage/face/styles/matrix_mouth.dart';
import 'package:ovos_gui_visage/face/styles/ring_eyes.dart';
import 'package:ovos_gui_visage/face/themes.dart';

import 'faults.dart';

void main() {
  test('the firmware tables ported: 6 listen, 4 talk, 7 think and 7 viseme frames of 8 rows within 32 columns', () {
    expect(listenFrames.length, 6);
    expect(talkFrames.length, 4);
    expect(thinkFrames.length, 7);
    expect(visemeFrames.length, 7);
    for (final table in [listenFrames, talkFrames, thinkFrames, visemeFrames]) {
      for (final frame in table) {
        expect(frame.length, mouthRows);
        expect(frame.every((row) => row >> mouthCols == 0), isTrue);
      }
    }
    expect(visemeFrames[4].where((row) => row != 0).length, 1, reason: 'the closed mouth is one straight row');
    expect(visemeFrames[0].where((row) => row != 0).length, greaterThan(4), reason: 'the open mouth spans rows');
  });

  test('the mouth frame follows the mode with the firmware step times', () {
    expect(mouthFrame(FaceMode.rest, 4, 1), isNull);
    expect(mouthFrame(FaceMode.speaking, 0, 1), visemeFrames[0]);
    expect(mouthFrame(FaceMode.speaking, 99, 1), visemeFrames[6]);
    expect(mouthFrame(FaceMode.listening, 4, 0), listenFrames[0]);
    expect(mouthFrame(FaceMode.listening, 4, 0.07), listenFrames[1]);
    expect(mouthFrame(FaceMode.listening, 4, 0.42), listenFrames[0]);
    expect(mouthFrame(FaceMode.thinking, 4, 0), thinkFrames[0]);
    expect(mouthFrame(FaceMode.thinking, 4, 0.12 * 6), thinkFrames[6]);
    expect(mouthFrame(FaceMode.thinking, 4, 0.12 * 7), thinkFrames[6], reason: 'the bounce holds the last frame twice');
    expect(mouthFrame(FaceMode.thinking, 4, 0.12 * 13), thinkFrames[0]);
  });

  test('narrowing turns off the top and bottom pairs first, a blink everything', () {
    expect(narrowDepth(1), 0);
    expect(narrowDepth(0.62), 2);
    expect(narrowDepth(0.08), 3);
    int lit(int depth) => List.generate(ringSize, (slot) => pixelLit(slot, depth)).where((v) => v).length;
    expect([lit(0), lit(1), lit(2), lit(3)], [12, 8, 4, 0]);
    expect([0, 11, 5, 6].every((slot) => !pixelLit(slot, 1)), isTrue);
    expect([2, 3, 8, 9].every((slot) => pixelLit(slot, 2)), isTrue, reason: 'the squint keeps the sides');
  });

  test('ring pixels run counter-clockwise from just past the top', () {
    final top = ringPixel(Offset.zero, 10, 0);
    expect(top.dy, lessThan(-9));
    expect(top.dx, lessThan(0));
    expect(ringPixel(Offset.zero, 10, 11).dx, greaterThan(0));
    expect(ringPixel(Offset.zero, 10, 6).dy, greaterThan(9));
  });

  test('the compact layout fits the badge disc', () {
    final layout = Mark1Layout.compact;
    final centre = const Mark1Theme().geometry.centre;
    final radius = const Mark1Theme().geometry.badgeRadius;
    for (final ring in layout.rings) {
      expect((ring - centre).distance + layout.ringRadius + layout.eyeLed, lessThan(radius));
    }
    final corner = layout.mouthOrigin + Offset((mouthCols - 1) * layout.pitch, (mouthRows - 1) * layout.pitch);
    expect((corner - centre).distance + layout.mouthLed, lessThan(radius));
    expect((layout.mouthOrigin - centre).distance + layout.mouthLed, lessThan(radius));
  });

  test('the badge rests on a short bar centred on the two middle rows', () {
    final lit = [
      for (var y = 0; y < mouthRows; y++)
        for (var x = 0; x < mouthCols; x++)
          if ((compactRestBar[y] >> x) & 1 == 1) (x, y),
    ];
    expect(lit, hasLength(20));
    expect(lit.map((p) => p.$2).toSet(), {3, 4});
    final xs = lit.map((p) => p.$1);
    expect(xs.reduce((a, b) => a < b ? a : b) + xs.reduce((a, b) => a > b ? a : b), mouthCols - 1, reason: 'centred');
  });

  test('the faceplate path parses its M, C, S and Z commands', () {
    final bounds = svgPath('M82.19 0C124 0 164.38 3 164.38 28.69S124 57.37 82.19 57.37S0 54.37 0 28.69S40.4 0 82.19 0Z')
        .getBounds();
    expect(bounds.left, closeTo(0, 0.01));
    expect(bounds.right, closeTo(164.38, 0.01));
    expect(bounds.bottom, closeTo(57.37, 0.01));
  });

  test('themes are picked by name and an unknown name reports and falls back', () async {
    final mark1 = faceThemeNamed('mark1') as ComposedTheme;
    expect(mark1.backdrop, isA<PlateBackdrop>());
    expect(mark1.eyeStyle, isA<RingEyes>());
    expect(mark1.mouthStyle, isA<MatrixMouth>());
    expect(faceThemeNamed('visage').geometry.top, 75);
    final faults = await collectFaults(() async => expect(faceThemeNamed('mark2').geometry.top, 75));
    expect(faults, hasLength(1));
  });

  test('the plate layout puts the styles in the ring wells and the matrix window', () {
    final layout = const PlateBackdrop().layout(false);
    final leds = Mark1Layout.full;
    expect(layout.left.centre, leds.rings[1]);
    expect(layout.right.centre, leds.rings[0]);
    expect(layout.left.radius, leds.ringRadius + leds.eyeLed);
    expect(layout.mouth.width, mouthCols * leds.pitch);
    expect(layout.mouth.centre.dx, closeTo(frameWidth / 2, 0.5));
    expect(const PlateBackdrop().maxMouthScale(false), 1, reason: 'the matrix window is hardware');
  });
}
