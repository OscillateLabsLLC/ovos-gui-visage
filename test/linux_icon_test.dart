import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_badge.dart';

const linuxAppId = 'net.oscillatelabs.ovos_gui_visage';
const linuxIconSizes = [48, 64, 128, 256, 512];

// Freedesktop app icons fill most of the canvas; a thin margin keeps the disc off the edge of a panel button.
const linuxBadgeShare = 0.92;

String linuxIconPath(int side) => '../linux/icons/hicolor/${side}x$side/apps/$linuxAppId.png';

/// The Linux app icon is the resting visage badge in the hicolor theme sizes, named after the GTK application id so
/// the desktop entry and the running window find it: `flutter test --update-goldens test/linux_icon_test.dart`
/// regenerates them. macOS only, like the face goldens.
void main() {
  for (final side in linuxIconSizes) {
    testWidgets('the $side px Linux app icon is the resting badge', (tester) async {
      tester.view.physicalSize = const Size(600, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final icon = SizedBox.square(
        dimension: side.toDouble(),
        child: Center(
          child: SizedBox.square(
            dimension: side * linuxBadgeShare,
            child: FaceBadge(controller: FaceController()),
          ),
        ),
      );
      await tester.pumpWidget(Center(child: RepaintBoundary(child: icon)));
      await expectLater(find.byType(RepaintBoundary), matchesGoldenFile(linuxIconPath(side)));
    }, skip: !Platform.isMacOS);
  }
}
