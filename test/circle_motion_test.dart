import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/theme.dart';
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

Finder _haloPaint() => find.descendant(of: find.byType(Glow), matching: find.byType(CustomPaint));

HaloPainter _halo(WidgetTester tester) => tester.widget<CustomPaint>(_haloPaint()).painter! as HaloPainter;

void main() {
  testWidgets('the halo is one gradient circle out to radius + spread + blur, never a blur', (tester) async {
    await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow()), still: true));
    expect(find.descendant(of: find.byType(Glow), matching: find.byType(DecoratedBox)), findsNothing);
    expect(tester.renderObject(_haloPaint()), paints..circle(x: 50, y: 50, radius: 50 + 2 + 34, hasMaskFilter: false));
  });

  group('under reduced motion', () {
    testWidgets('the glow holds its mid-breath frame and schedules no frames', (tester) async {
      const colour = Color(0xFF1E9BFF);
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow(colour: colour)), still: true));
      expect(_halo(tester).colour.a, closeTo(colour.a * (0.45 + 0.55 * glowStillPhase), 1e-6));
      expect(await _tickers(tester), 0);
      await tester.pump(const Duration(seconds: 3));
      expect(_halo(tester).colour.a, closeTo(colour.a * (0.45 + 0.55 * glowStillPhase), 1e-6));
    });

    testWidgets('a looping glow holds its mid swell', (tester) async {
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow(loop: true)), still: true));
      expect([_halo(tester).blur, _halo(tester).spread], [34 + 30 * glowStillPhase, 2 + 12 * glowStillPhase]);
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
    final first = _halo(tester).colour.a;
    expect(find.byType(Opacity), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(_halo(tester).colour.a, isNot(first));
    expect(await _tickers(tester), greaterThan(0));
  });

  group('bloom', () {
    testWidgets('swells once to the loop peak at 1.1 s, then settles into the breath', (tester) async {
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow(bloom: true)), still: false));
      expect([_halo(tester).blur, _halo(tester).spread], [34, 2]);
      await tester.pump(glowSwell);
      expect(_halo(tester).blur, closeTo(64, 0.01));
      expect(_halo(tester).spread, closeTo(14, 0.01));
      expect(_halo(tester).colour.a, closeTo(VisageColors.accentSoft.a, 1e-6));
      await tester.pump(glowSwell);
      expect([_halo(tester).blur, _halo(tester).spread], [34, 2]);
      expect(await _tickers(tester), greaterThan(0), reason: 'the breath goes on');
    });

    testWidgets('without bloom the glow starts at rest', (tester) async {
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow()), still: false));
      await tester.pump(glowSwell);
      expect(_halo(tester).blur, 34);
    });

    testWidgets('under reduced motion a bloom holds the still frame', (tester) async {
      await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow(bloom: true)), still: true));
      expect(_halo(tester).blur, 34);
      expect(_halo(tester).colour.a, closeTo(VisageColors.accentSoft.a * (0.45 + 0.55 * glowStillPhase), 1e-6));
      expect(await _tickers(tester), 0);
    });
  });

  group('item cadence', () {
    double opacityOf(WidgetTester tester, String text) =>
        tester.widget<Opacity>(find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first).opacity;
    double scaleOf(WidgetTester tester, String text) => tester
        .widget<Transform>(find.ancestor(of: find.text(text), matching: find.byType(Transform)).first)
        .transform
        .entry(0, 0);

    testWidgets('each item pops in over 200 ms, 100 ms after the one before', (tester) async {
      await tester.pumpWidget(_frame(const StaggerEnter(children: [Text('a'), Text('b'), Text('c')]), still: false));
      expect(['a', 'b', 'c'].map((t) => opacityOf(tester, t)), everyElement(0));
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacityOf(tester, 'a'), 1, reason: 'shown within the first half of its pop');
      expect(opacityOf(tester, 'b'), closeTo(0, 1e-9), reason: 'b starts only now');
      await tester.pump(const Duration(milliseconds: 100));
      expect(scaleOf(tester, 'a'), closeTo(1, 1e-9));
      expect(opacityOf(tester, 'b'), 1);
      expect(opacityOf(tester, 'c'), closeTo(0, 1e-9));
      await tester.pump(const Duration(milliseconds: 200));
      expect(scaleOf(tester, 'c'), closeTo(1, 1e-9));
    });

    testWidgets('a pop overshoots its size a little before it settles', (tester) async {
      await tester.pumpWidget(_frame(const StaggerEnter(children: [Text('a')]), still: false));
      var peak = 0.0;
      for (var ms = 0; ms < 200; ms += 10) {
        await tester.pump(const Duration(milliseconds: 10));
        if (scaleOf(tester, 'a') > peak) peak = scaleOf(tester, 'a');
      }
      expect(peak, inInclusiveRange(1.005, 1.03));
    });

    testWidgets('items past the sixth start with it', (tester) async {
      expect(enterDelay(9), enterDelay(enterMaxIndex));
      await tester.pumpWidget(_frame(const RiseIn(index: 9, child: Text('late')), still: false));
      await tester.pump(enterGap * enterMaxIndex);
      expect(opacityOf(tester, 'late'), 0);
      await tester.pump(enterDuration);
      expect(opacityOf(tester, 'late'), 1);
    });
  });

  testWidgets('turning reduced motion on while running stops the glow', (tester) async {
    await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow()), still: false));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(_frame(const SizedBox.square(dimension: 100, child: Glow()), still: true));
    expect(await _tickers(tester), 0);
  });
}
