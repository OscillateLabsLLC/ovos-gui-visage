import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_badge.dart';

const traySide = 64.0;

/// The Linux tray icon is the resting visage badge, kept in step with the painters: `flutter test --update-goldens
/// test/tray_icon_test.dart` regenerates `assets/tray/ovos-gui-visage.png`. macOS only, like the face goldens.
void main() {
  testWidgets('the tray icon is the resting badge', (tester) async {
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: traySide,
            child: FaceBadge(controller: FaceController()),
          ),
        ),
      ),
    );
    await expectLater(find.byType(RepaintBoundary), matchesGoldenFile('../assets/tray/ovos-gui-visage.png'));
  }, skip: !Platform.isMacOS);
}
