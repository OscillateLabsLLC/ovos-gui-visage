import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_badge.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';

void main() {
  for (final preset in ['visage', 'mark1']) {
    testWidgets('the $preset badge fills a small square with the compact face, centred on the disc', (tester) async {
      final controller = FaceController(theme: FaceSpec.parse(preset).theme());
      await tester.pumpWidget(
        Center(
          child: SizedBox.square(dimension: 96, child: FaceBadge(controller: controller)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      final face = tester.widget<Face>(find.byType(Face));
      expect(face.compact, isTrue);
      final fitted = tester.getRect(find.byType(FittedBox));
      expect(fitted.size, const Size(96, 96));
      final geometry = controller.theme.geometry;
      final scale = 96 / (2 * geometry.badgeRadius);
      final faceRect = tester.getRect(find.byType(Face));
      expect(faceRect.topLeft + geometry.centre * scale, offsetMoreOrLessEquals(fitted.center));
      expect(tester.takeException(), isNull);
    });
  }
}
