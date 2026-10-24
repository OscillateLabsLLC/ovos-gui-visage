/// GUI-1 frames onto the same [GuiState] the legacy protocol fills, so the router, the pages and the face read one
/// model. Under GUI-1 a namespace holds exactly one page, named with its template, and its data is always the full
/// map the adapter sent: Visage never merges.
library;

import 'package:flutter/foundation.dart';

import '../faults.dart';
import '../pages/router.dart';
import '../pages/template_names.dart';
import '../protocol/gui1_frames.dart';
import '../status_topics.dart';
import 'gui_state.dart';

/// What GUI-1 frames ask for that Visage cannot do, each told once so a stream never spams the log. A template or a
/// status topic without a page or a role is a fault ([TemplateGaps], [reportFault]); an `idle` while this session still
/// holds a stack is the spec's device-wide idle (finding F16), logged.
class Gui1Gaps {
  Gui1Gaps({TemplateGaps? templates, this.log = _debugLog}) : templates = templates ?? templateGaps;

  final TemplateGaps templates;
  final void Function(String) log;
  final _told = <String>{};

  void unknownStatus(String topic) {
    if (!_told.add('status $topic')) return;
    reportFault('GUI-1 status', ArgumentError.value(topic, 'event_name', 'not a status topic Visage follows'));
  }

  void idleWhileShowing(List<String> active) {
    if (_told.add('idle')) log('GUI-1 (finding F16): idle while this session shows $active; ignored, logged once');
  }
}

void _debugLog(String line) => debugPrint(line);

final gui1Gaps = Gui1Gaps();

/// Applies one frame for [sessionId]. `welcome` and `error` change no state; `status` changes none either, and a topic
/// Visage does not follow is told through [gaps]. A frame for another session is reported and ignored; an unknown
/// `SYSTEM_*` template is told through [gaps] and still shown, as the fallback. `idle` empties the state only when this
/// session's stack is already empty, since ovos-gui sends it when any session's stack empties.
void applyGui1Frame(GuiState state, Gui1Frame frame, {String sessionId = defaultSessionId, Gui1Gaps? gaps}) {
  final told = gaps ?? gui1Gaps;
  final session = _sessionOf(frame);
  if (session != null && session != sessionId) {
    return reportFault('GUI-1 frame', StateError('frame for session $session, this display is $sessionId'));
  }
  switch (frame) {
    case Gui1Template(:final skillId, :final template, :final data):
      _checkTemplate(template, told.templates);
      _show(state, skillId, template, data);
      _activate(state, skillId);
    case Gui1SessionUpdate(:final skillId, :final data):
      state.namespace(skillId).data = Json.of(data);
    case Gui1Activated(:final skillId):
      _activate(state, skillId);
    case Gui1Deactivated(:final skillId):
      state.active.remove(skillId);
      state.namespaces.remove(skillId);
    case Gui1Idle() when state.active.isEmpty:
      state.reset();
    case Gui1Idle():
      told.idleWhileShowing(state.active);
    case Gui1Snapshot(:final stack):
      _replace(state, stack, told.templates);
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

void _show(GuiState state, String skillId, String? template, Json data) {
  final ns = state.namespace(skillId)
    ..data = Json.of(data)
    ..clearPages();
  if (template != null) ns.pages = [template];
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
    _show(state, entry.skillId, entry.template, entry.data);
    state.active.add(entry.skillId);
  }
}

/// A skill's own template name passes through to its skill route; a `SYSTEM_` name outside the vocabulary has no
/// page anywhere, so it is reported once and degrades to the fallback.
void _checkTemplate(String template, TemplateGaps gaps) {
  if (template.startsWith(systemPrefix) && canonicalTemplate(template) == null) gaps.unknown(template);
}
