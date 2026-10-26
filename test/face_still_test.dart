/// The face under reduced motion (or VISAGE_MOTION=cut): a still frame, with visemes switching as discrete shapes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/face/visemes.dart';

Widget _face(FaceController controller, {required bool still}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Face(controller: controller),
  ),
);

FaceFrame _frame(WidgetTester tester) =>
    (tester.widget<CustomPaint>(find.descendant(of: find.byType(Face), matching: find.byType(CustomPaint))).painter!
            as FacePainter)
        .frame;

void main() {
  testWidgets('at rest the face holds a still frame: eyes open, mouth at rest, no blink, no widen, nothing ticking', (
    tester,
  ) async {
    final controller = FaceController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_face(controller, still: true));
    controller.widen();
    for (var second = 0; second < 10; second++) {
      await tester.pumpWidget(_face(controller, still: true));
      await tester.pump(const Duration(seconds: 1));
      final frame = _frame(tester);
      expect([frame.eyeOpen, frame.eyeScale, frame.elapsed, frame.viseme], [1, 1, 0, restCode], reason: 'at $second s');
      expect(frame.lips, controller.theme.mouthShapes[restCode]);
    }
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('speaking, the mouth switches to each viseme shape at once, with no tween', (tester) async {
    final controller = FaceController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_face(controller, still: true));
    controller
      ..setMode(FaceMode.speaking)
      ..playVisemes([
        [2, 100.0],
      ]);
    await tester.pumpWidget(_face(controller, still: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(_frame(tester).viseme, 2);
    expect(_frame(tester).lips, controller.theme.mouthShapes[2], reason: 'the shape itself, not a step towards it');
    expect(tester.binding.transientCallbackCount, greaterThan(0), reason: 'it ticks while it speaks');
    controller.setMode(FaceMode.rest);
    await tester.pumpWidget(_face(controller, still: true));
    await tester.pump();
    expect([_frame(tester).viseme, tester.binding.transientCallbackCount], [restCode, 0]);
  });

  testWidgets('with motion the face keeps its own clock running', (tester) async {
    final controller = FaceController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_face(controller, still: false));
    await tester.pump(const Duration(milliseconds: 500));
    expect(_frame(tester).elapsed, greaterThan(0));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
  });
}
