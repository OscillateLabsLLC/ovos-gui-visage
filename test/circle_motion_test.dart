import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/widgets/circle.dart';

Widget _frame(Widget child, {required bool still}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Material(child: Center(child: child)),
  ),
);

/// Live tickers after one more frame; the binding schedules frames of its own, so this is the measure of motion.
Future<int> _tickers(WidgetTester tester) async {
  await tester.pump();
  return tester.binding.transientCallbackCount;
}

BoxShadow _shadow(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(Glow), matching: find.byType(DecoratedBox)));
  return (box.decoration as BoxDecoration).boxShadow!.single;
}

void main() {
  group('under reduced motion', () {
    testWidgets('the glow holds its mid-breath frame and schedules no frames', (tester) async {
      const colour = Color(0xFF1E9BFF);
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow(colour: colour)), still: true));
      expect(_shadow(tester).color.a, closeTo(colour.a * (0.45 + 0.55 * glowStillPhase), 1e-6));
      expect(await _tickers(tester), 0);
      await tester.pump(const Duration(seconds: 3));
      expect(_shadow(tester).color.a, closeTo(colour.a * (0.45 + 0.55 * glowStillPhase), 1e-6));
    });

    testWidgets('a looping glow holds its mid swell', (tester) async {
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow(loop: true)), still: true));
      expect([_shadow(tester).blurRadius, _shadow(tester).spreadRadius], [34 + 30 * glowStillPhase, 2 + 12 * glowStillPhase]);
      expect(await _tickers(tester), 0);
    });

    testWidgets('stagger enter and rise in show their children in place at full opacity at once', (tester) async {
      await tester.pumpWidget(
        _frame(
          const Column(
            children: [
              StaggerEnter(children: [Text('a'), Text('b')]),
              RiseIn(index: 3, child: Text('c')),
            ],
          ),
          still: true,
        ),
      );
      expect([find.byType(Opacity), find.byType(Transform)], everyElement(findsNothing));
      expect([find.text('a'), find.text('b'), find.text('c')], everyElement(findsOneWidget));
      expect(await _tickers(tester), 0);
    });

    testWidgets('a ring draws its value at once', (tester) async {
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Ring(fraction: 0.4)), still: true));
      expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
      expect(await _tickers(tester), 0);
    });
  });

  testWidgets('with motion allowed the glow breathes and the children rise in', (tester) async {
    await tester.pumpWidget(
      _frame(
        const Column(
          children: [
            SizedBox.square(dimension: 100, child: Glow()),
            StaggerEnter(children: [Text('a')]),
          ],
        ),
        still: false,
      ),
    );
    final first = _shadow(tester).color.a;
    expect(find.byType(Opacity), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(_shadow(tester).color.a, isNot(first));
    expect(await _tickers(tester), greaterThan(0));
  });

  testWidgets('turning reduced motion on while running stops the glow', (tester) async {
    await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow()), still: false));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow()), still: true));
    expect(await _tickers(tester), 0);
  });
}
