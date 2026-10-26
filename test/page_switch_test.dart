import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/circle.dart';
import 'package:ovos_gui_visage/widgets/notification_list.dart';
import 'package:ovos_gui_visage/widgets/page_moves.dart';
import 'package:ovos_gui_visage/widgets/page_switch.dart';

import 'gui1_fixture.dart' as gui1;
import 'recording_bus.dart';

Widget _host(Widget child, {bool still = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(size: const Size(432, 736), disableAnimations: still),
    child: Material(child: child),
  ),
);

Future<void> _show(WidgetTester tester, String key, {Object? group, int index = 0, Widget? child, bool still = false}) =>
    tester.pumpWidget(
      _host(
        PageSwitch(pageKey: key, group: group, index: index, child: child ?? Text(key)),
        still: still,
      ),
    );

/// Advances from [from] to [ms] in 10 ms frames, as the screen would; one long pump is a single frame.
Future<void> _at(WidgetTester tester, int ms, {required int from}) async {
  for (var t = from; t < ms; t += 10) {
    await tester.pump(Duration(milliseconds: (ms - t).clamp(0, 10)));
  }
}

PagePose _ms(PagePose? Function(PageMove, Duration) pose, PageMove move, int ms) => pose(move, Duration(milliseconds: ms))!;

double _dx(WidgetTester tester, String text) => tester
    .widget<FractionalTranslation>(find.ancestor(of: find.text(text), matching: find.byType(FractionalTranslation)).first)
    .translation
    .dx;

/// Counts its mounts and disposals, to see when a page is kept alive.
class _Probe extends StatefulWidget {
  const _Probe(this.label, this.log);

  final String label;
  final List<String> log;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.log.add('+${widget.label}');
  }

  @override
  void dispose() {
    widget.log.add('-${widget.label}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  group('which move', () {
    test('a step between pages of one skill slides in its direction; anything else swaps', () {
      expect(pageMove(fromGroup: 'a', fromIndex: 0, toGroup: 'a', toIndex: 1), PageMove.forward);
      expect(pageMove(fromGroup: 'a', fromIndex: 2, toGroup: 'a', toIndex: 1), PageMove.back);
      expect(pageMove(fromGroup: 'a', fromIndex: 0, toGroup: 'b', toIndex: 1), PageMove.swap);
      expect(
        pageMove(fromGroup: 'a', toGroup: 'a'),
        PageMove.swap,
        reason: 'a new page in the same place',
      );
      expect(pageMove(toGroup: 'a', toIndex: 1), PageMove.swap, reason: 'from the resting page');
    });
  });

  group('the swap timeline', () {
    test('the old page grows a little, squashes to a line that holds, and is gone at 320 ms', () {
      expect(_ms(leavingPose, PageMove.swap, 60).scaleY, closeTo(anticipateScale, 1e-9));
      expect(_ms(leavingPose, PageMove.swap, 120).scaleY, lessThan(anticipateScale));
      expect(_ms(leavingPose, PageMove.swap, 220).scaleY, closeTo(lineScale, 1e-9));
      expect(_ms(leavingPose, PageMove.swap, 300).scaleY, lineScale);
      expect(_ms(leavingPose, PageMove.swap, 300).opacity, lessThan(_ms(leavingPose, PageMove.swap, 220).opacity));
      expect(leavingPose(PageMove.swap, const Duration(milliseconds: 320)), isNull);
    });

    test('the new page expands out of the line from 320 ms, overshoots, and stands at 520 ms', () {
      expect(arrivingPose(PageMove.swap, const Duration(milliseconds: 319)), isNull);
      expect(_ms(arrivingPose, PageMove.swap, 320).scaleY, lineScale);
      final peak = [for (var ms = 320; ms <= 520; ms += 5) _ms(arrivingPose, PageMove.swap, ms).scaleY]
          .reduce((a, b) => a > b ? a : b);
      expect(peak, greaterThan(1));
      expect(_ms(arrivingPose, PageMove.swap, 520), restingPose);
      expect(swapLength, const Duration(milliseconds: 520));
    });

    test('the page expand overshoots by 2 to 4 percent of the page height; the item pop keeps easeOutBack', () {
      double peak(Curve curve) => [for (var i = 0; i <= 10000; i++) curve.transform(i / 10000)].reduce(math.max);
      expect(peak(expandCurve), inInclusiveRange(1.02, 1.04));
      expect(peak(expandCurve), closeTo(1.0234, 0.0005), reason: 'the value page_moves.dart documents');
      expect(arriveCurve, Curves.easeOutBack);
      final heights = [for (var ms = 320; ms <= 520; ms += 2) _ms(arrivingPose, PageMove.swap, ms).scaleY];
      expect(heights.reduce(math.max), inInclusiveRange(1.019, 1.04));
    });

    test('a slide moves both pages a full width together, in the step direction', () {
      expect(_ms(leavingPose, PageMove.forward, 100).dx, closeTo(-0.5, 1e-9));
      expect(leavingPose(PageMove.forward, slideLength), isNull);
      expect(_ms(arrivingPose, PageMove.forward, 0).dx, 1);
      expect(_ms(arrivingPose, PageMove.back, 0).dx, -1);
      expect(_ms(arrivingPose, PageMove.back, 200), restingPose);
    });
  });

  group('PageSwitch', () {
    testWidgets('a new shape: the old page stays mounted through its exit, the new one arrives at 320 ms', (tester) async {
      final log = <String>[];
      await _show(tester, 'a', child: _Probe('a', log));
      await _show(tester, 'b', child: _Probe('b', log));
      await _at(tester, 250, from: 0);
      expect(find.text('a'), findsOneWidget, reason: 'the line holds');
      expect(find.text('b'), findsNothing);
      expect(log, ['+a']);
      await _at(tester, 330, from: 250);
      expect([find.text('a'), find.text('b')], [findsNothing, findsOneWidget]);
      expect(log, unorderedEquals(['+a', '-a', '+b']));
      await _at(tester, 600, from: 330);
      expect(log, hasLength(3), reason: 'the new page keeps its state when the move ends');
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a page that changes again during the squash replaces the one waiting to arrive', (tester) async {
      await _show(tester, 'a');
      await _show(tester, 'b');
      await _at(tester, 100, from: 0);
      await _show(tester, 'c');
      await _at(tester, 330, from: 100);
      expect([find.text('a'), find.text('b'), find.text('c')], [findsNothing, findsNothing, findsOneWidget]);
    });

    testWidgets('a step slides the old page out and the new one in together', (tester) async {
      await _show(tester, 'one', group: 'skill');
      await _show(tester, 'two', group: 'skill', index: 1);
      await _at(tester, 100, from: 0);
      expect(_dx(tester, 'one'), lessThan(0));
      expect(_dx(tester, 'two'), greaterThan(0));
      await _show(tester, 'one', group: 'skill');
      await _at(tester, 300, from: 100);
      expect(find.text('two'), findsNothing);
      await _show(tester, 'zero', group: 'skill');
      expect(find.text('zero'), findsNothing, reason: 'a new page at the same index swaps, so it waits for the line');
      await _at(tester, 330, from: 0);
      expect(find.text('zero'), findsOneWidget);
    });

    testWidgets('a step back slides the other way', (tester) async {
      await _show(tester, 'two', group: 'skill', index: 1);
      await _show(tester, 'one', group: 'skill');
      await _at(tester, 100, from: 0);
      expect(_dx(tester, 'two'), greaterThan(0));
      expect(_dx(tester, 'one'), lessThan(0));
    });

    testWidgets('the new page\'s items enter after its expand; a sliding page arrives whole', (tester) async {
      double opacity() =>
          tester.widget<Opacity>(find.ancestor(of: find.text('item'), matching: find.byType(Opacity)).first).opacity;
      await _show(tester, 'a');
      await _show(tester, 'b', child: const StaggerEnter(children: [Text('item')]));
      await _at(tester, 420, from: 0);
      expect(opacity(), 0, reason: 'the page is still expanding');
      await _at(tester, 620, from: 420);
      expect(opacity(), closeTo(1, 1e-9));
      await _show(tester, 'c', group: 'g');
      await _at(tester, 1200, from: 620);
      await _show(
        tester,
        'd',
        group: 'g',
        index: 1,
        child: const StaggerEnter(children: [Text('item')]),
      );
      await tester.pump();
      expect(opacity(), 1, reason: 'no pop inside a slide');
    });

    testWidgets('PageHost: a template squashes the resting page away, and a clear brings it back the same way', (tester) async {
      final state = GuiState();
      final notifications = NotificationListController(bus: RecordingBus(), storage: ValueNotifier(const []));
      Future<void> render() => tester.pumpWidget(
        gui1.host(PageHost(state: state, send: (_) => true, notifications: notifications, protocol: ChosenProtocol.gui1)),
      );
      await render();
      expect(find.byType(RestingPage), findsOneWidget);
      gui1.replayGui1([
        gui1.template(gui1.hello, 'SYSTEM_text', {'text': 'Hi'}),
      ], state: state);
      await render();
      await _at(tester, 250, from: 0);
      expect([find.byType(RestingPage), find.text('Hi')], [findsOneWidget, findsNothing]);
      await _at(tester, 600, from: 250);
      expect([find.byType(RestingPage), find.text('Hi')], [findsNothing, findsOneWidget]);
      gui1.replayGui1([gui1.template(gui1.hello, 'Idle.qml', {})], state: state);
      await render();
      await _at(tester, 250, from: 0);
      expect([find.byType(RestingPage), find.text('Hi')], [findsNothing, findsOneWidget]);
      await _at(tester, 600, from: 250);
      expect([find.byType(RestingPage), find.text('Hi')], [findsOneWidget, findsNothing]);
    });

    testWidgets('under reduced motion every change is a cut', (tester) async {
      await _show(tester, 'a', still: true);
      await _show(tester, 'b', still: true);
      expect([find.text('a'), find.text('b')], [findsNothing, findsOneWidget]);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
