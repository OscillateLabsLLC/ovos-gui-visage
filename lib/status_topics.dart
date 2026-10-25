/// The status topics the face follows, keyed by their OVOS-GUI-1 names (gui-1.md §5.3, ovos-gui `STATUS_TOPICS`). The
/// legacy bus names are aliases of them, so both protocols drive [Attention] the same way. Every §5.3 topic has a role.
library;

enum StatusRole { listenStart, listenEnd, thinkStart, thinkEnd, failed, speakStart, speakEnd, visemes, sleep, awoken }

const specStatusRoles = {
  'ovos.listener.wakeword': StatusRole.listenStart,
  'ovos.listener.record.started': StatusRole.listenStart,
  'ovos.listener.record.ended': StatusRole.listenEnd,
  'ovos.stt.failed': StatusRole.failed,
  'ovos.utterance.handle': StatusRole.thinkStart,
  'ovos.intent.handler.start': StatusRole.thinkStart,
  'ovos.intent.handler.complete': StatusRole.thinkEnd,
  'ovos.intent.handler.error': StatusRole.failed,
  'ovos.intent.unmatched': StatusRole.thinkEnd,
  'ovos.utterance.handled': StatusRole.thinkEnd,
  'ovos.utterance.speak': StatusRole.thinkEnd,
  'ovos.audio.output.started': StatusRole.speakStart,
  'ovos.audio.output.ended': StatusRole.speakEnd,
  'ovos.audio.output.visemes': StatusRole.visemes,
  'ovos.listener.sleep': StatusRole.sleep,
  'ovos.listener.awoken': StatusRole.awoken,
};

/// The bus names ovos-core, the listener and the audio service sent before the §5.3 names, each to the spec topic it
/// became. Sleep and awoken follow ovos-spec-tools' `MIGRATION_MAP`; the listener sends
/// `recognizer_loop:speech.recognition.unknown` when speech to text returns nothing (ovos-dinkum-listener `service.py`).
const legacyStatusAliases = {
  'recognizer_loop:wakeword': 'ovos.listener.wakeword',
  'recognizer_loop:record_begin': 'ovos.listener.record.started',
  'recognizer_loop:record_end': 'ovos.listener.record.ended',
  'recognizer_loop:speech.recognition.unknown': 'ovos.stt.failed',
  'recognizer_loop:utterance': 'ovos.utterance.handle',
  'mycroft.skill.handler.start': 'ovos.intent.handler.start',
  'mycroft.skill.handler.complete': 'ovos.intent.handler.complete',
  'mycroft.skill.handler.error': 'ovos.intent.handler.error',
  'complete_intent_failure': 'ovos.intent.unmatched',
  'speak': 'ovos.utterance.speak',
  'recognizer_loop:audio_output_start': 'ovos.audio.output.started',
  'recognizer_loop:audio_output_end': 'ovos.audio.output.ended',
  'enclosure.mouth.viseme_list': 'ovos.audio.output.visemes',
  'recognizer_loop:sleep': 'ovos.listener.sleep',
  'mycroft.awoken': 'ovos.listener.awoken',
};

/// What [topic], by its spec name or a legacy alias, does to the face; null for a topic Visage does not follow.
StatusRole? statusRole(String topic) => specStatusRoles[legacyStatusAliases[topic] ?? topic];
