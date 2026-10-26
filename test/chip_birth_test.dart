import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/widgets/chip_birth.dart';

import 'gui1_fixture.dart';

final _two = stackedChips([170, 300], 28);
final _one = stackedChips([300], 28);

BirthFrame _at(int ms, List<BirthChip> chips) => birthFrame(Duration(milliseconds: ms), chips);

Widget _framed(Widget child, {bool still = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: Material(
      child: Center(child: SizedBox(width: 432, height: 736, child: child)),
    ),
  ),
);

double _content(WidgetTester tester) =>
    tester.widget<Opacity>(find.descendant(of: find.byType(ChipBirth), matching: find.byType(Opacity)).first).opacity;

Finder _discs() => find.byWidgetPredicate((w) => w is CustomPaint && '${w.painter.runtimeType}' == '_BirthPainter');

void main() {
  test('the chips land where a centred column puts them', () {
    expect(_two, [(dy: -164.0, size: 170.0), (dy: 99.0, size: 300.0)]);
    expect(_one, [(dy: 0.0, size: 300.0)]);
  });

  group('two chips', () {
    test('one disc pops in between where the chips will sit', () {
      final frame = _at(50, _two);
      expect(frame.discs, hasLength(1));
      expect(frame.discs.single.dy, (-164 + 99) / 2);
      expect(frame.discs.single.radius, greaterThan(0));
      expect([frame.waist, frame.content], [0, 0]);
    });

    test('it stretches into a peanut: two overlapping halves joined by a narrower waist', () {
      final frame = _at(250, _two);
      final [top, bottom] = frame.discs;
      expect(bottom.dy - top.dy, lessThan(top.radius + bottom.radius), reason: 'the halves overlap');
      expect(frame.waist, inExclusiveRange(0, 2 * top.radius));
    });

    test('it splits into two discs that land on the chips, then the chips fade in as the discs fade out', () {
      final landed = _at(400, _two);
      expect(landed.discs, [(dy: -164.0, radius: 85.0), (dy: 99.0, radius: 150.0)]);
      expect([landed.waist, landed.discOpacity, landed.content], [0, 1, 0]);
      final fading = _at(450, _two);
      expect(fading.discOpacity, closeTo(0.5, 1e-9));
      expect(fading.content, closeTo(0.5, 1e-9));
      expect(_at(500, _two), (discs: const <Disc>[], waist: 0.0, discOpacity: 0.0, content: 1.0));
    });
  });

  test('one chip: the disc grows into it, with no peanut', () {
    expect(_at(200, _one).discs, hasLength(1));
    expect(_at(200, _one).waist, 0);
    expect(_at(300, _one).discs.single, (dy: 0.0, radius: 150.0));
  });

  testWidgets('the resting page is born when it appears, and its chips then stand', (tester) async {
    const ambient = {
      ambientWeather: {'current_temp': 21, 'condition': 'Cloudy', 'condition_code': 'cloudy'},
    };
    await tester.pumpWidget(_framed(RestingPage(ambient: ambient, now: () => restingNow)));
    expect(_content(tester), 0);
    expect(_discs(), findsOneWidget);
    for (var ms = 0; ms < 600; ms += 20) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(_content(tester), 1);
    expect(_discs(), findsNothing);
    expect(find.text('21°'), findsOneWidget);
  });

  testWidgets('under reduced motion the chips stand at once', (tester) async {
    await tester.pumpWidget(_framed(RestingPage(ambient: const {}, now: () => restingNow), still: true));
    expect(_content(tester), 1);
    expect(_discs(), findsNothing);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
