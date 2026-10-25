import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';
import 'package:ovos_gui_visage/outcome.dart';
import 'package:ovos_gui_visage/theme.dart';
import 'package:ovos_gui_visage/widgets/offline_pill.dart';
import 'package:ovos_gui_visage/widgets/outcome_pill.dart';

import 'corebus_fixture.dart';
import 'manual_timers.dart';

void main() {
  late ManualTimers timers;
  late OutcomeModel model;
  late List<Outcome?> changes;

  setUp(() {
    timers = ManualTimers();
    model = OutcomeModel(timer: timers.create);
    changes = [];
    model.addListener(() => changes.add(model.showing));
  });

  void replay(String fixture) {
    for (final (type, data) in coreBusFixture(fixture)) {
      model.handle(type, data);
    }
  }

  for (final (fixture, expected) in const [
    ('turn_what_time_is_it', Outcome.success),
    ('turn_cancelled', Outcome.cancelled),
    ('turn_unmatched', Outcome.failure),
    ('turn_handler_error', Outcome.failure),
  ]) {
    test('$fixture shows ${expected.name} once, at the end marker', () {
      replay(fixture);
      expect(changes, [expected]);
    });
  }

  test('nothing shows before the end marker', () {
    replayUntil(coreBusFixture('turn_what_time_is_it'), handlerCompleteEvent, model.handle);
    expect(model.showing, isNull);
  });

  test('the outcome hides after its time on screen', () {
    replay('turn_what_time_is_it');
    expect(timers.pending.single.after, outcomeShownFor);
    timers.fireAll();
    expect(changes, [Outcome.success, null]);
  });

  test('a handler completion carrying an exception is a failure, as older skill frameworks report it', () {
    model.handle(handlerCompleteEvent, {'name': 'TimeSkill.handle_query_time', 'exception': 'ValueError()'});
    model.handle(turnEndEvent, {});
    expect(model.showing, Outcome.failure);
  });

  test('a failure earlier in the turn wins over a later completion', () {
    model.handle('mycroft.skill.handler.error', {'exception': 'boom'});
    model.handle(handlerCompleteEvent, {});
    model.handle(turnEndEvent, {});
    expect(model.showing, Outcome.failure);
  });

  test('a handler error by its orchestrator name fails the turn at its end marker', () {
    model.handle('ovos.intent.handler.error', {'exception': 'ZeroDivisionError'});
    expect(model.showing, isNull);
    model.handle(turnEndEvent, {});
    expect(model.showing, Outcome.failure);
  });

  test('speech to text failing shows the failure at once, by either name, since no turn follows', () {
    for (final event in sttFailedEvents) {
      model.handle(event, {});
      expect(model.showing, Outcome.failure, reason: event);
      timers.fireAll();
      expect(model.showing, isNull);
    }
  });

  test('a new utterance forgets the previous turn\'s verdict', () {
    model.handle('complete_intent_failure', {});
    model.handle(turnStartEvent, {
      'utterances': ['again'],
    });
    model.handle(turnEndEvent, {});
    expect(model.showing, Outcome.success);
  });

  test('a second turn ending restarts the timer rather than stacking', () {
    replay('turn_what_time_is_it');
    replay('turn_cancelled');
    expect(timers.pending, hasLength(1));
    expect(model.showing, Outcome.cancelled);
  });

  test('success follows the colourway; cancelled is grey and failure red', () {
    expect(outcomeColour(Outcome.success, FacePalette.ember), FacePalette.ember.accent);
    expect(outcomeColour(Outcome.cancelled, FacePalette.mint), VisageColors.muted);
    expect(outcomeColour(Outcome.failure, FacePalette.ember), VisageColors.bad);
  });

  testWidgets('the pill shows the label and goes when the outcome clears', (tester) async {
    Widget host(Outcome? outcome) => MaterialApp(
      home: Stack(
        children: [
          TopStatus(children: [OutcomePill(outcome: outcome)]),
        ],
      ),
    );
    await tester.pumpWidget(host(null));
    expect(find.byType(StatusPill), findsNothing);
    await tester.pumpWidget(host(Outcome.failure));
    await tester.pumpAndSettle();
    expect(find.text("Didn't work"), findsOneWidget);
    await tester.pumpWidget(host(null));
    await tester.pumpAndSettle();
    expect(find.byType(StatusPill), findsNothing);
  });
}
