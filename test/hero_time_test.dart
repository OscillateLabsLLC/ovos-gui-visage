import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/time_page.dart';
import 'package:ovos_gui_visage/widgets/hero_time.dart';
import 'package:ovos_gui_visage/widgets/home_chips.dart';

import 'gui1_fixture.dart';

/// The time's natural width (the FittedBox scales it down to its box when it is wider) and the box it must fit.
({double natural, double box}) measure(WidgetTester tester) => (
  natural: tester.getSize(find.descendant(of: find.byType(HeroTime), matching: find.byType(Text))).width,
  box: tester.getSize(find.byType(HeroTime)).width,
);

void main() {
  testWidgets('a five-glyph time is scaled into the clock chip box', (tester) async {
    await tester.pumpWidget(host(const ClockChip(time: '10:27', ampm: 'PM', date: 'Sunday, 25 October')));
    final wide = measure(tester);
    expect(wide.box, closeTo(clockChipSize * heroTimeWidthFraction, 0.5));
    expect(wide.natural, greaterThan(wide.box), reason: 'at 92 px five glyphs are wider than the box, so they scale down');

    // The test font draws every glyph one em wide, so a four-glyph time is 360 px here and 206 px in the system
    // font; only the box can be checked. With the system font 206 < 228, so a four-glyph time is drawn at full size.
    await tester.pumpWidget(host(const ClockChip(time: '9:05', ampm: 'AM', date: 'Sunday, 25 October')));
    expect(measure(tester).box, closeTo(clockChipSize * heroTimeWidthFraction, 0.5));
  });

  testWidgets('the time page ring fits a five-glyph time the same way', (tester) async {
    await tester.pumpWidget(host(const ClockRing(time: '10:27', ampm: 'PM', date: 'Sunday, 25 October')));
    final wide = measure(tester);
    expect(wide.box, closeTo(380 * heroTimeWidthFraction, 0.5));
    expect(wide.natural, greaterThan(wide.box));
  });
}
