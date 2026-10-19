import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_badge.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';

// A maskable icon keeps its content inside the centre 80% circle, which every launcher mask leaves visible.
const maskableBadgeShare = 0.6;

const plainIcons = {'../web/favicon.png': 32, '../web/icons/Icon-192.png': 192, '../web/icons/Icon-512.png': 512};
const maskableIcons = {'../web/icons/Icon-maskable-192.png': 192, '../web/icons/Icon-maskable-512.png': 512};

/// The favicon and the web app icons are the resting visage badge, kept in step with the painters:
/// `flutter test --update-goldens test/web_icon_test.dart` regenerates them. macOS only, like the face goldens.
void main() {
  for (final MapEntry(key: file, value: side) in plainIcons.entries) {
    testWidgets('$file is the resting badge', (tester) async {
      await _expectIcon(tester, file, SizedBox.square(dimension: side.toDouble(), child: _badge()));
    }, skip: !Platform.isMacOS);
  }
  for (final MapEntry(key: file, value: side) in maskableIcons.entries) {
    testWidgets('$file is the resting badge inside the mask safe zone', (tester) async {
      final icon = Container(
        width: side.toDouble(),
        height: side.toDouble(),
        color: HardwareColours.blade,
        alignment: Alignment.center,
        child: SizedBox.square(dimension: side * maskableBadgeShare, child: _badge()),
      );
      await _expectIcon(tester, file, icon);
    }, skip: !Platform.isMacOS);
  }
}

Widget _badge() => FaceBadge(controller: FaceController());

Future<void> _expectIcon(WidgetTester tester, String file, Widget icon) async {
  tester.view.physicalSize = const Size(600, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(Center(child: RepaintBoundary(child: icon)));
  await expectLater(find.byType(RepaintBoundary), matchesGoldenFile(file));
}
