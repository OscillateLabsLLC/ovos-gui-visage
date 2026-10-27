import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/face/visemes.dart';

void main() {
  testWidgets('the face paints in every mode and follows a viseme list', (tester) async {
    final controller = FaceController();
    await tester.pumpWidget(MaterialApp(home: Face(controller: controller)));
    for (final mode in FaceMode.values) {
      controller.setMode(mode);
      await tester.pump(const Duration(milliseconds: 100));
    }
    controller.setMode(FaceMode.speaking);
    controller.playVisemes([
      ['0', 0.5],
      ['2', 1.0],
    ], at: const Duration(seconds: 1));
    expect(controller.targetCode(const Duration(milliseconds: 1200)), 0);
    expect(controller.targetCode(const Duration(milliseconds: 1700)), 2);
    expect(controller.targetCode(const Duration(milliseconds: 2500)), restCode);
    controller.setMode(FaceMode.rest);
    expect(controller.targetCode(const Duration(milliseconds: 1200)), restCode);
    expect(tester.takeException(), isNull);
  });

  test('eyes close when sleeping or blinking and narrow when thinking', () {
    final controller = FaceController();
    expect(controller.targetEyeOpen, 1);
    controller.setMode(FaceMode.thinking);
    expect(controller.targetEyeOpen, lessThan(1));
    controller.setSleeping(true);
    expect(controller.targetEyeOpen, lessThan(0.1));
  });

  testWidgets('a blink or widen still in flight when the controller is disposed never notifies (finding F37)', (tester) async {
    FaceController()
      ..blink()
      ..widen()
      ..dispose();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
