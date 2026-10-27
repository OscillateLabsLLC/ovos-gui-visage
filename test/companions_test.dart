/// The interactive companions of the drafted amendment A: the pure models, the pages from the hand-written fixtures
/// (`test/fixtures/gui1/system_{confirm,select,input}.jsonl`), the reply each answer sends and the GUI-1 frame it
/// becomes, degradation, and the reduced-motion still frame.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/companions_model.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/select_page.dart';
import 'package:ovos_gui_visage/pages/template_keys.dart';
import 'package:ovos_gui_visage/protocol/gui1_outgoing.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const _demo = 'ovos-skill-gui1-demo.oscillatelabs';

/// Pumps the page [scenario] ends on, with a GUI-1 context whose sends land in [sent] as GUI-1 frames.
Future<void> _pump(WidgetTester tester, String scenario, List<Json> sent, {bool still = false}) async {
  final state = replayGui1(loadGui1Fixture(scenario));
  final target = state.current()!;
  final ctx = PageContext(
    namespace: target.namespace,
    page: target.page,
    events: const {},
    protocol: ChosenProtocol.gui1,
    send: (event) {
      sent.add(gui1FrameFor(event)!);
      return true;
    },
  );
  final page = resolve(target, gaps: freshGaps().templates)(state.namespace(target.namespace).data, ctx);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: still),
      child: host(page),
    ),
  );
  if (!still) await tester.pump(const Duration(seconds: 1));
}

Json _reply(String event, Json data) => interactionFrame(_demo, event, data);

void main() {
  setUp(forgetReportedKeys);

  group('models', () {
    test('confirm: the labels default to Yes and No; a missing question is reported', () async {
      final faults = await collectFaults(() async => expect(confirmModel(const {}), (question: '', yes: 'Yes', no: 'No')));
      expect(faults.map((f) => '${f.exception}'), ['FormatException: question is required']);
    });

    test('select: an item without a label, or with a value that is not a string or number, is reported and dropped', () async {
      late List<Choice> choices;
      final faults = await collectFaults(() async {
        choices = selectModel({
          'prompt': 'Pick',
          'items': [
            {'label': 'A', 'value': 'a'},
            {'value': 'b'},
            {'label': 'C', 'value': <String, dynamic>{}},
            {'label': 'D', 'value': 4, 'image': '/Users/me/d.png'},
          ],
        }).choices;
      });
      expect([for (final c in choices) (c.label, c.value, c.image)], [('A', 'a', null), ('D', 4, null)]);
      expect(faults, hasLength(3), reason: 'the missing label, the object value, the path image (finding F39)');
    });

    test('input: secret masks only when it is true; another type is reported', () async {
      expect(inputModel({'prompt': 'p', 'secret': true}).secret, isTrue);
      final faults = await collectFaults(() async => expect(inputModel({'prompt': 'p', 'secret': 'yes'}).secret, isFalse));
      expect(faults.single.exceptionAsString(), contains('secret must be a boolean'));
    });
  });

  group('pages', () {
    testWidgets('SYSTEM_confirm: the question over two round answers; each sends confirm with its answer', (tester) async {
      final sent = <Json>[];
      await _pump(tester, 'system_confirm', sent);
      expect(find.text('Turn off the kitchen lights?'), findsOneWidget);
      await tester.tap(find.text('Turn off'));
      await tester.tap(find.text('Leave on'));
      expect(sent, [
        _reply(confirmEvent, {'answer': true}),
        _reply(confirmEvent, {'answer': false}),
      ]);
    });

    testWidgets('SYSTEM_select: one answer per item, each sending its value unchanged', (tester) async {
      final sent = <Json>[];
      await _pump(tester, 'system_select', sent);
      expect(find.text('Which colour?'), findsOneWidget);
      await tester.tap(find.text('Number three'));
      await tester.tap(find.text('Blue'));
      expect(sent, [
        _reply(selectEvent, {'value': 3}),
        _reply(selectEvent, {'value': 'blue'}),
      ]);
    });

    testWidgets('SYSTEM_input: Enter or Send sends input with the text; no exit button', (tester) async {
      final sent = <Json>[];
      await _pump(tester, 'system_input', sent);
      expect([find.text('What should I call you?'), find.text('Your name')], everyElement(findsOneWidget));
      expect(find.text('Exit'), findsNothing);
      await tester.enterText(find.byType(TextField), 'Ada');
      await tester.tap(find.text('Send'));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(sent, [
        _reply(inputEvent, {'text': 'Ada'}),
        _reply(inputEvent, {'text': 'Ada'}),
      ]);
      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isFalse);
    });

    testWidgets('reduced motion: each companion stands still at full opacity on its first frame', (tester) async {
      for (final (scenario, text) in [('system_confirm', 'Turn off'), ('system_select', 'Blue'), ('system_input', 'Send')]) {
        await _pump(tester, scenario, [], still: true);
        expect(
          find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
          findsNothing,
          reason: scenario,
        );
        expect(find.byType(TweenAnimationBuilder<double>), findsNothing, reason: scenario);
      }
    });
  });

  group('degradation', () {
    testWidgets('a select without items is reported and keeps the prompt with a voice hint', (tester) async {
      final ctx = PageContext(namespace: _demo, page: selectTemplate, events: const {});
      final faults = await collectFaults(() async {
        await tester.pumpWidget(host(SelectPage.page(const {'prompt': 'Pick one'}, ctx)));
        await tester.pump(const Duration(seconds: 1));
      });
      expect([find.text('Pick one'), find.text(noChoices)], everyElement(findsOneWidget));
      expect(faults.single.exceptionAsString(), contains('items is required'));
    });

    test('a companion is a known template, so GUI-1 reports no unknown name for it', () async {
      final state = GuiState();
      final faults = await collectFaults(() async {
        replayGui1([
          template(_demo, inputTemplate, const {'prompt': 'p'}),
        ], state: state);
      });
      expect(faults, isEmpty);
      expect(state.current(), const Target(_demo, inputTemplate, 0));
    });
  });
}
