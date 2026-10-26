import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/confirm_page.dart';
import 'package:ovos_gui_visage/pages/inner_pager.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/page_pager.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

const _pageBox = Size(432, 736);

/// Fourteen sentences page to five pages in the shell's page box (measured).
final _fivePages = List.generate(14, (i) => 'Sentence number $i tells a little more.').join(' ');

/// The page under the shell as screen_frame.dart and screen_input.dart put it: the inner pages step first, then the
/// skill's (recorded in [skillSteps]).
class _Shell {
  final slot = InnerPagerSlot();
  final skillSteps = <int>[];

  void step(int delta) {
    if (!slot.step(delta)) skillSteps.add(delta);
  }

  Widget host(Widget page, {int count = 1}) => MaterialApp(
    home: WindowSurface(
      mode: WindowMode.kiosk,
      onLeaveKiosk: () {},
      onStep: step,
      child: Material(
        child: Center(
          child: SizedBox.fromSize(
            size: _pageBox,
            child: PagePager(index: 0, count: count, onStep: step, onInteract: () {}, chevrons: true, inner: slot, child: page),
          ),
        ),
      ),
    ),
  );
}

int _shown(WidgetTester tester) => tester.widget<PageDots>(find.byType(PageDots)).active;

Future<void> _tapAt(WidgetTester tester, double fraction) async {
  final box = tester.getRect(find.byType(PagePager));
  await tester.tapAt(Offset(box.left + box.width * fraction, box.center.dy));
  await tester.pump();
}

Future<_Shell> _longText(WidgetTester tester) async {
  final shell = _Shell();
  await tester.pumpWidget(shell.host(TextFramePage(data: {'text': _fivePages})));
  await tester.pump();
  expect(tester.widget<PageDots>(find.byType(PageDots)).count, 5, reason: 'the text pages to five');
  expect(shell.slot.current, isNotNull, reason: 'the page published its inner pages');
  return shell;
}

void main() {
  group('the model', () {
    test('a person\'s step stops at either end, holds the turning once, and the page\'s own turn does not', () {
      final pager = InnerPager(count: 3, pageTime: (_) => const Duration(seconds: 10));
      expect([pager.canStep(-1), pager.step(-1)], [false, false]);
      expect(pager.step(1), isTrue);
      expect(pager.takeHold(), const Duration(seconds: 30));
      expect(pager.takeHold(), isNull);
      pager.turnTo(2);
      expect([pager.index, pager.takeHold(), pager.canStep(1)], [2, null, false]);
    });

    test('the hold is three page times, at least 20 s', () {
      expect(autoHoldAfterStep(const Duration(seconds: 4)), const Duration(seconds: 20));
      expect(autoHoldAfterStep(const Duration(seconds: 9)), const Duration(seconds: 27));
    });

    test('a tap steps back in the left third, ahead in the right third, and not in the middle', () {
      expect([tapStep(10, 432), tapStep(216, 432), tapStep(420, 432)], [-1, 0, 1]);
    });
  });

  testWidgets('a five-page text steps by key, swipe, tap and chevron; the dots follow; past its ends the skill steps', (
    tester,
  ) async {
    final shell = await _longText(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_shown(tester), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_shown(tester), 0);
    await tester.fling(find.byType(TextFramePage), const Offset(-200, 0), 800);
    await tester.pump();
    expect(_shown(tester), 1, reason: 'a swipe left is forwards');
    await _tapAt(tester, 0.9);
    expect(_shown(tester), 2);
    await _tapAt(tester, 0.5);
    expect(_shown(tester), 2, reason: 'the middle third does nothing');
    await _tapAt(tester, 0.1);
    expect(_shown(tester), 1);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(_shown(tester), 2);
    expect(shell.skillSteps, isEmpty);
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
    }
    expect(
      [_shown(tester), shell.skillSteps],
      [
        0,
        [-1],
      ],
      reason: 'at the first page, back steps the skill',
    );
  });

  testWidgets('the turning waits after a manual step, then goes on from the page shown', (tester) async {
    final shell = await _longText(tester);
    final pager = shell.slot.current!;
    await tester.pump(pager.pageTime(0) + const Duration(milliseconds: 50));
    expect(_shown(tester), 1, reason: 'it turns by itself');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_shown(tester), 2);
    final hold = autoHoldAfterStep(pager.pageTime(2));
    await tester.pump(hold - const Duration(seconds: 1));
    expect(_shown(tester), 2, reason: 'held');
    await tester.pump(const Duration(seconds: 2));
    expect(_shown(tester), 3, reason: 'on from the page shown');
  });

  testWidgets('a page without inner pages: keys and swipes step the skill, and a tap steps nothing', (tester) async {
    final shell = _Shell();
    await tester.pumpWidget(shell.host(const ColoredBox(color: Colors.black), count: 2));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _tapAt(tester, 0.1);
    expect(shell.skillSteps, [1]);
  });

  testWidgets('the tap zones never take a tap from a page\'s own button', (tester) async {
    final shell = _Shell();
    final sent = <Json>[];
    final ctx = PageContext(
      namespace: 'demo',
      page: 'SYSTEM_confirm',
      events: const {},
      send: (m) {
        sent.add(m);
        return true;
      },
    );
    final pager = InnerPager(count: 3, pageTime: (_) => const Duration(seconds: 5))..step(1);
    await tester.pumpWidget(shell.host(ConfirmPage(data: const {'question': 'Turn off the lights?'}, ctx: ctx)));
    shell.slot.publish(pager);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final yes = tester.getRect(find.text('Yes'));
    final box = tester.getRect(find.byType(PagePager));
    expect(yes.center.dx, lessThan(box.left + box.width / 3), reason: 'the button sits in the left tap zone');
    await tester.tapAt(yes.center);
    await tester.pump();
    expect(sent, hasLength(1), reason: 'the button took the tap');
    expect(pager.index, 1, reason: 'the inner pages did not step back');
    await tester.tapAt(Offset(box.left + 20, box.top + 20));
    await tester.pump();
    expect(pager.index, 0, reason: 'off the button, the same zone steps back: it was live');
  });
}
