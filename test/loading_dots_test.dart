import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/loading_page.dart';

Widget _loading({required bool still}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: const Material(child: LoadingPage(data: {})),
  ),
);

/// The three dots' opacities, left to right.
List<double> _dots(WidgetTester tester) => [
  for (final dot in tester.widgetList<Opacity>(find.ancestor(of: find.byType(DecoratedBox), matching: find.byType(Opacity))))
    dot.opacity,
];

void main() {
  testWidgets('under reduced motion every dot holds the middle of a breath and nothing ticks', (tester) async {
    await tester.pumpWidget(_loading(still: true));
    expect(_dots(tester), List.filled(3, dotOpacity(0.5)));
    final scales = tester.widgetList<Transform>(find.ancestor(of: find.byType(DecoratedBox), matching: find.byType(Transform)));
    expect(scales, hasLength(3));
    expect(scales.map((t) => t.transform.entry(0, 0)), everyElement(closeTo(dotScale(0.5), 1e-9)));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('with motion the dots breathe in turn', (tester) async {
    await tester.pumpWidget(_loading(still: false));
    await tester.pump(const Duration(milliseconds: 300));
    final first = _dots(tester);
    expect(first.toSet(), hasLength(greaterThan(1)), reason: 'the dots are out of step');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_dots(tester), isNot(first));
  });
}
