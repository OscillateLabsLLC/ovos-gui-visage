import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_remote.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/face/face_theme.dart';
import 'package:ovos_gui_visage/face/try_on.dart';

import 'recording_bus.dart';

void main() {
  late FaceController controller;
  late FaceRemote remote;

  Widget host() => MaterialApp(
    home: Center(
      child: SizedBox(
        width: frameWidth,
        height: frameHeight,
        child: Stack(
          children: [FaceTryOn(controller: controller, remote: remote)],
        ),
      ),
    ),
  );

  setUp(() {
    controller = FaceController();
    remote = FaceRemote(RecordingBus(), controller, initial: FaceSpec.visage, persist: (_) async {});
  });

  testWidgets('long-press enters, swipes cycle eyes and mouth, a vertical swipe sizes the mouth, tap leaves', (tester) async {
    await tester.pumpWidget(host());
    expect(find.textContaining('eyes ·'), findsNothing);
    final box = tester.getRect(find.byType(FaceTryOn));
    final eyes = box.topLeft + const Offset(240, 190);
    final mouth = box.topLeft + const Offset(240, 480);

    await tester.longPressAt(eyes);
    await tester.pump();
    expect(find.text('‹  eyes · lens  ›'), findsOneWidget);
    expect(controller.mode, FaceMode.speaking);

    await tester.dragFrom(eyes, const Offset(120, 0));
    await tester.pump();
    expect(remote.spec.eyes, 'ring');
    await tester.dragFrom(eyes, const Offset(-120, 0));
    await tester.dragFrom(eyes, const Offset(-120, 0));
    await tester.pump();
    expect(remote.spec.eyes, 'dot', reason: 'cycling backwards wraps round');

    await tester.dragFrom(mouth, const Offset(120, 0));
    await tester.pump();
    expect(remote.spec.mouth, 'solid');
    await tester.dragFrom(mouth, const Offset(0, -120));
    await tester.pump();
    expect(remote.spec.mouthSize, 'large');
    await tester.dragFrom(mouth, const Offset(0, 120));
    await tester.pump();
    expect(remote.spec.mouthSize, 'regular');
    expect(find.text('‹  mouth · solid · regular  ›'), findsOneWidget);

    await tester.tapAt(eyes);
    await tester.pump();
    expect(find.textContaining('eyes ·'), findsNothing);
    expect(controller.mode, FaceMode.rest);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the demo loop keeps the mouth speaking while trying on', (tester) async {
    await tester.pumpWidget(host());
    final at = tester.getRect(find.byType(FaceTryOn)).center;
    await tester.longPressAt(at);
    await tester.pump();
    controller.setMode(FaceMode.rest);
    await tester.pump(const Duration(seconds: 2));
    expect(controller.mode, FaceMode.speaking);
    await tester.tapAt(at);
    await tester.pump();
  });
}
