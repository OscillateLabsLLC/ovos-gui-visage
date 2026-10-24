import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/protocol/gui_events.dart';

import 'faults.dart';

const skill = 'ovos-skill-alerts.openvoiceos';

/// One recorded round trip per line: what this app sent on the GUI socket, and the core bus message ovos-gui emitted.
List<Json> roundTrips(String name) => [
  for (final line in File('test/fixtures/outgoing/$name.jsonl').readAsLinesSync())
    if (line.trim().isNotEmpty) jsonDecode(line) as Json,
];

void main() {
  test('an event goes out in the page namespace with its parameters, as mycroft-gui sends it', () {
    expect(guiEvent(skill, 'input.box.response', {'text': 'hi'}), {
      'type': 'mycroft.events.triggered',
      'namespace': skill,
      'event_name': 'input.box.response',
      'parameters': {'text': 'hi'},
    });
  });

  test('system events go out in the system namespace', () {
    expect(interactionMessage(skill), {
      'type': 'mycroft.events.triggered',
      'namespace': 'system',
      'event_name': 'system.gui.user.interaction',
      'parameters': {'skillId': skill},
    });
  });

  test('focus carries the page number and the skill id', () {
    expect(focusMessage(skill, 1)['parameters'], {'number': 1, 'skillId': skill});
    expect(focusMessage(skill, 1)['namespace'], skill);
  });

  test('ovos-gui maps focus, interaction and other events to these bus messages', () {
    expect(busMessageFor(focusMessage(skill, 2)), {
      'type': 'gui.page_gained_focus',
      'data': {'namespace': skill, 'page_number': 2, 'skill_id': skill},
    });
    expect(busMessageFor(interactionMessage(skill))['type'], 'gui.page_interaction');
    expect(busMessageFor(guiEvent(skill, 'input.box.close')), {'type': '$skill.input.box.close', 'data': <String, dynamic>{}});
  });

  for (final name in ['input_box_round_trip', 'page_focus_round_trip', 'ocp_controls_round_trip', 'alerts_controls_round_trip']) {
    test('the recorded round trip $name matches what the app builds and what ovos-gui emitted', () {
      for (final trip in roundTrips(name)) {
        final sent = trip['sent'] as Json;
        final rebuilt = guiEvent(sent['parameters']['skillId'] ?? sent['namespace'], sent['event_name'], sent['parameters']);
        expect(rebuilt, sent);
        expect(busMessageFor(sent), {'type': trip['bus']['type'], 'data': trip['bus']['data']});
      }
    });
  }

  testWidgets('a page trigger that cannot leave is reported', (tester) async {
    const ctx = PageContext(namespace: skill, page: 'Timer', events: {});
    final faults = await collectFaults(() async => ctx.trigger('x'));
    expect(faults.single.context.toString(), contains('$skill/Timer sending x'));
    final sent = <Json>[];
    PageContext(
      namespace: skill,
      page: 'Timer',
      events: const {},
      send: (m) {
        sent.add(m);
        return true;
      },
    ).trigger('y', {'a': 1});
    expect(sent.single, guiEvent(skill, 'y', {'a': 1}));
  });
}
