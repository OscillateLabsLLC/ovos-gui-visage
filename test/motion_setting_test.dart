import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/widgets/circle.dart';

/// The root as main.dart builds it: a MaterialApp whose builder is [motionBuilder].
Widget _app(MotionSetting setting, Widget home) => MaterialApp(builder: motionBuilder(setting), home: home);

void main() {
  for (final (setting, disabled) in [(MotionSetting.cut, true), (MotionSetting.full, false)]) {
    testWidgets('under ${setting.name} the root MediaQuery reports disableAnimations $disabled', (tester) async {
      late bool seen;
      await tester.pumpWidget(
        _app(
          setting,
          Builder(
            builder: (context) {
              seen = motionReduced(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, disabled);
    });
  }

  testWidgets('under cut a blooming glow holds its still frame and schedules nothing', (tester) async {
    await tester.pumpWidget(
      _app(MotionSetting.cut, const Center(child: SizedBox.square(dimension: 100, child: Glow(bloom: true)))),
    );
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
