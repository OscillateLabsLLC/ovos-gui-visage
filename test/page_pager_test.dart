import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/page_pager.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

GuiState twoPages() => GuiState()
  ..apply({
    'type': 'mycroft.session.list.insert',
    'namespace': activeSkills,
    'position': 0,
    'data': [
      {'skill_id': 'w'},
    ],
  })
  ..apply({
    'type': 'mycroft.gui.list.insert',
    'namespace': 'w',
    'position': 0,
    'data': [
      {'page': 'A'},
      {'page': 'B'},
    ],
  });

Widget pager({int index = 0, int count = 2, bool chevrons = false, List<int>? steps, List<String>? log}) => MaterialApp(
  home: PagePager(
    index: index,
    count: count,
    onStep: (d) => steps?.add(d),
    onInteract: () => log?.add('use'),
    chevrons: chevrons,
    child: const ColoredBox(key: Key('page'), color: Colors.black),
  ),
);

void main() {
  test('steps stop at either end', () {
    expect(pageStep(0, 2, 1), 1);
    expect(pageStep(1, 2, 1), isNull);
    expect(pageStep(0, 2, -1), isNull);
  });

  test('a swipe left is forwards; a short slow one is nothing', () {
    expect(swipeStep(-80, 0), 1);
    expect(swipeStep(80, 0), -1);
    expect(swipeStep(-10, -500), 1);
    expect(swipeStep(-10, -50), 0);
  });

  test('focusing a page moves the target; out of range or the same page is refused', () {
    final state = twoPages();
    expect(state.focusPage('w', 1), isTrue);
    expect(state.current(), const Target('w', 'B', 1));
    expect(state.focusPage('w', 1), isFalse);
    expect(state.focusPage('w', 2), isFalse);
    expect(state.focusPage('nobody', 0), isFalse);
  });

  testWidgets('a swipe on a skill with pages steps; a press counts as use', (tester) async {
    final steps = <int>[], log = <String>[];
    await tester.pumpWidget(pager(steps: steps, log: log));
    await tester.fling(find.byKey(const Key('page')), const Offset(-200, 0), 800);
    await tester.pumpAndSettle();
    expect(steps, [1]);
    expect(log, ['use']);
  });

  for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('on a widget a clearly horizontal drag turns the page and any other drag moves the window ($kind)', (
      tester,
    ) async {
      final steps = <int>[];
      var moves = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: WindowSurface(
            mode: WindowMode.float,
            onLeaveKiosk: () {},
            onDragStart: () => moves++,
            child: PagePager(
              index: 0,
              count: 2,
              onStep: steps.add,
              onInteract: () {},
              chevrons: false,
              child: const ColoredBox(key: Key('page'), color: Colors.black),
            ),
          ),
        ),
      );
      final centre = tester.getCenter(find.byKey(const Key('page')));
      Future<void> drag(Offset by) async {
        final gesture = await tester.startGesture(centre, kind: kind);
        for (var i = 1; i <= 10; i++) {
          await gesture.moveBy(by / 10, timeStamp: Duration(milliseconds: 30 * i));
        }
        await gesture.up();
        await tester.pump();
      }

      await drag(const Offset(-200, 10));
      await drag(const Offset(-150, -160));
      await drag(const Offset(4, 200));
      expect(steps, [1]);
      expect(moves, 2);
    });
  }

  testWidgets('one page has no swipe and no chevrons', (tester) async {
    final steps = <int>[];
    await tester.pumpWidget(pager(count: 1, chevrons: true, steps: steps));
    await tester.fling(find.byKey(const Key('page')), const Offset(-200, 0), 800);
    expect(steps, isEmpty);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('kiosk chevrons show only where there is a page to go to', (tester) async {
    final steps = <int>[];
    await tester.pumpWidget(pager(chevrons: true, steps: steps));
    expect(find.byIcon(Icons.chevron_left), findsNothing);
    await tester.tap(find.byIcon(Icons.chevron_right));
    expect(steps, [1]);
    await tester.pumpWidget(pager(index: 1, chevrons: true, steps: steps));
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.tap(find.byIcon(Icons.chevron_left));
    expect(steps, [1, -1]);
  });

  testWidgets('the arrow keys step pages', (tester) async {
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: WindowSurface(mode: WindowMode.window, onLeaveKiosk: () {}, onStep: steps.add, child: const SizedBox()),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(steps, [1, -1]);
  });
}
