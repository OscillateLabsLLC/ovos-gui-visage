import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/status_topics.dart';

/// ovos-gui's `STATUS_TOPICS` (gui-1.md §5.3), copied from ovos_gui/gui1.py, not from lib/.
const specTopics = {
  'ovos.listener.wakeword',
  'ovos.listener.record.started',
  'ovos.listener.record.ended',
  'ovos.stt.failed',
  'ovos.utterance.handle',
  'ovos.intent.handler.start',
  'ovos.intent.handler.complete',
  'ovos.intent.handler.error',
  'ovos.intent.unmatched',
  'ovos.utterance.handled',
  'ovos.utterance.speak',
  'ovos.audio.output.visemes',
  'ovos.audio.output.started',
  'ovos.audio.output.ended',
  'ovos.listener.sleep',
  'ovos.listener.awoken',
};

void main() {
  test('every followed topic is a §5.3 topic, and every legacy alias names one with the same role', () {
    expect(specTopics, containsAll(specStatusRoles.keys));
    for (final MapEntry(key: legacy, value: spec) in legacyStatusAliases.entries) {
      expect(specStatusRoles, contains(spec), reason: legacy);
      expect(statusRole(legacy), statusRole(spec), reason: legacy);
    }
  });

  test('the legacy topics keep the roles the face gave them before GUI-1', () {
    expect(statusRole('recognizer_loop:record_begin'), StatusRole.listenStart);
    expect(statusRole('speak'), StatusRole.thinkEnd);
    expect(statusRole('recognizer_loop:audio_output_end'), StatusRole.speakEnd);
    expect(statusRole('enclosure.mouth.viseme_list'), StatusRole.visemes);
  });

  test('topics Visage does not follow yet have no role', () {
    for (final topic in ['ovos.stt.failed', 'ovos.listener.sleep', 'gui.ambient.weather', 'mycroft.skill.handler.error']) {
      expect(statusRole(topic), isNull, reason: topic);
    }
  });
}
