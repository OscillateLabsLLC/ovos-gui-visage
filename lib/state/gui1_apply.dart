/// GUI-1 frames onto the same [GuiState] the legacy protocol fills, so the router, the pages and the face read one
/// model. Under GUI-1 a namespace holds exactly one page, named with its template, and its data is always the full
/// map the adapter sent: Visage never merges.
library;

import '../faults.dart';
import '../pages/router.dart';
import '../pages/template_names.dart';
import '../protocol/gui1_frames.dart';
import '../status_topics.dart';
import 'ambient.dart';
import 'gui_state.dart';

/// What GUI-1 frames ask for that Visage cannot do, each told once so a stream never spams the log. A template or a
/// status topic without a page or a role, an ambient payload without the keys gui-1.md 6.9.1 requires, and an `idle`
/// for another session are faults ([TemplateGaps], [reportFault]).
class Gui1Gaps {
  Gui1Gaps({TemplateGaps? templates}) : templates = templates ?? templateGaps;

  final TemplateGaps templates;
  final _told = <String>{};

  void unknownStatus(String topic) {
    if (!_told.add('status $topic')) return;
    reportFault('GUI-1 status', ArgumentError.value(topic, 'event_name', 'not a status topic Visage follows'));
  }

  void incompleteAmbient(String topic, List<String> missing) {
    if (!_told.add('ambient $topic')) return;
    reportFault('GUI-1 ambient', ArgumentError.value(topic, 'event_name', 'lacks ${missing.join(', ')}; not shown'));
  }

  /// Amendment D sends `idle` only to the session whose stack emptied, so another session's is a protocol fault.
  void foreignIdle(String session, String own) {
    if (!_told.add('idle $session')) return;
    reportFault('GUI-1 idle', StateError('idle for session $session, this display is $own; ignored'));
  }

  void notAmbient(String topic) {
    if (!_told.add('snapshot ambient $topic')) return;
    reportFault('GUI-1 snapshot', ArgumentError.value(topic, 'ambient', 'not a gui.ambient.* topic; not kept'));
  }
}

final gui1Gaps = Gui1Gaps();

/// Applies one frame for [sessionId]. `welcome` and `error` change no state; a `gui.ambient.*` status, or a snapshot's
/// `ambient`, is kept in [GuiState.ambient], any other `status` changes none, and a topic Visage does not follow is told
/// through [gaps]. A frame for another session is reported and ignored (an `idle` once per session); an unknown
/// `SYSTEM_*` template is told through [gaps] and still shown, as the fallback. This session's `idle` empties the state,
/// so the resting page shows (amendment D; it supersedes finding F16).
void applyGui1Frame(
  GuiState state,
  Gui1Frame frame, {
  String sessionId = defaultSessionId,
  Gui1Gaps? gaps,
  DateTime Function() now = DateTime.now,
}) {
  final told = gaps ?? gui1Gaps;
  if (frame case Gui1Idle(sessionId: final session) when session != sessionId) return told.foreignIdle(session, sessionId);
  final session = _sessionOf(frame);
  if (session != null && session != sessionId) {
    return reportFault('GUI-1 frame', StateError('frame for session $session, this display is $sessionId'));
  }
  switch (frame) {
    case Gui1Template(:final skillId, :final template, :final data, :final entry):
      _checkTemplate(template, told.templates);
      _show(state, skillId, template, data, entry);
      _activate(state, skillId);
    case Gui1SessionUpdate(:final skillId, :final data):
      state.namespace(skillId).data = Json.of(data);
    case Gui1Activated(:final skillId):
      _activate(state, skillId);
    case Gui1Deactivated(:final skillId):
      state.active.remove(skillId);
      state.namespaces.remove(skillId);
    case Gui1Idle():
      state.reset();
    case Gui1Snapshot(:final stack, :final ambient):
      _replace(state, stack, told.templates);
      ambient.forEach((topic, data) => _keepSnapshotAmbient(state, topic, data, told, now()));
    case Gui1Status(:final eventName, :final data) when isAmbientTopic(eventName):
      _keepAmbient(state, eventName, data, told, now());
    case Gui1Status(:final eventName) when statusRole(eventName) == null:
      told.unknownStatus(eventName);
    case Gui1Welcome() || Gui1Error() || Gui1Status():
      break;
  }
}

String? _sessionOf(Gui1Frame frame) => switch (frame) {
  Gui1Template(:final sessionId) ||
  Gui1SessionUpdate(:final sessionId) ||
  Gui1Activated(:final sessionId) ||
  Gui1Deactivated(:final sessionId) ||
  Gui1Snapshot(:final sessionId) => sessionId,
  _ => null,
};

void _keepSnapshotAmbient(GuiState state, String topic, Json data, Gui1Gaps gaps, DateTime at) =>
    isAmbientTopic(topic) ? _keepAmbient(state, topic, data, gaps, at) : gaps.notAmbient(topic);

void _keepAmbient(GuiState state, String topic, Json data, Gui1Gaps gaps, DateTime at) {
  state.ambient[topic] = Json.of(data);
  state.ambientAt[topic] = at;
  final missing = missingAmbientKeys(topic, data);
  if (missing.isNotEmpty) gaps.incompleteAmbient(topic, missing);
}

const idleTemplate = 'SYSTEM_idle';

/// `SYSTEM_idle` asks for the resting state and names no page (gui-1.md 3.4 and 6.9; finding F33): its namespace keeps its place
/// on the stack without one, so the page beneath it, or the resting display, shows.
void _show(GuiState state, String skillId, String? template, Json data, Gui1Entry? entry) {
  final ns = state.namespace(skillId)
    ..data = Json.of(data)
    ..clearPages();
  if (template != null && canonicalTemplate(template) != idleTemplate) ns.pages = [template];
  ns.gui1Entry = entry;
}

void _activate(GuiState state, String skillId) {
  state.active
    ..remove(skillId)
    ..insert(0, skillId);
}

void _replace(GuiState state, List<Gui1StackEntry> stack, TemplateGaps gaps) {
  state.reset();
  for (final entry in stack) {
    if (entry.template case final template?) _checkTemplate(template, gaps);
    _show(state, entry.skillId, entry.template, entry.data, entry.entry);
    state.active.add(entry.skillId);
  }
}

/// A skill's own template name passes through to its skill route; a `SYSTEM_` name outside the vocabulary has no
/// page anywhere, so it is reported once and degrades to the fallback.
void _checkTemplate(String template, TemplateGaps gaps) {
  if (template.startsWith(systemPrefix) && canonicalTemplate(template) == null) gaps.unknown(template);
}
