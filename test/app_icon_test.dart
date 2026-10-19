import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_badge.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';

const iconSizes = [16, 32, 64, 128, 256, 512, 1024];
const iconSet = '../macos/Runner/Assets.xcassets/AppIcon.appiconset';

// Apple's macOS icon grid on a 1024 canvas: an 824 tile with a 185 corner radius.
const tileShare = 824 / 1024;
const cornerShare = 185 / 1024;
const badgeShare = 0.62;

/// The macOS app icon is the resting visage badge on a housing-grey tile, kept in step with the painters:
/// `flutter test --update-goldens test/app_icon_test.dart` regenerates every size in the app icon set. macOS only, like
/// the face goldens.
void main() {
  for (final side in iconSizes) {
    testWidgets('the $side px app icon is the resting badge on its tile', (tester) async {
      tester.view.physicalSize = const Size(1100, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(child: AppIconTile(side: side.toDouble())),
        ),
      );
      await expectLater(find.byType(RepaintBoundary), matchesGoldenFile('$iconSet/app_icon_$side.png'));
    }, skip: !Platform.isMacOS);
  }
}

class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    final tile = side * tileShare;
    return SizedBox.square(
      dimension: side,
      child: Center(
        child: Container(
          width: tile,
          height: tile,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: HardwareColours.blade, borderRadius: BorderRadius.circular(side * cornerShare)),
          child: SizedBox.square(
            dimension: tile * badgeShare,
            child: FaceBadge(controller: FaceController()),
          ),
        ),
      ),
    );
  }
}
