/// GUI-1 frames onto the same [GuiState] the legacy protocol fills, so the router, the pages and the face read one
/// model. Under GUI-1 a namespace holds exactly one page, named with its template, and its data is always the full
/// map the adapter sent: Visage never merges.
library;

import '../faults.dart';
import '../pages/router.dart';
import '../pages/template_names.dart';
import '../protocol/gui1_frames.dart';
import 'gui_state.dart';

/// Applies one frame for [sessionId]. `status`, `welcome` and `error` change no state and are left to the caller.
/// A frame for another session is reported and ignored; an unknown `SYSTEM_*` template is reported through [gaps]
/// and still shown, as the fallback.
void applyGui1Frame(GuiState state, Gui1Frame frame, {String sessionId = defaultSessionId, TemplateGaps? gaps}) {
  final session = _sessionOf(frame);
  if (session != null && session != sessionId) {
    return reportFault('GUI-1 frame', StateError('frame for session $session, this display is $sessionId'));
  }
  switch (frame) {
    case Gui1Template(:final skillId, :final template, :final data):
      _checkTemplate(template, gaps ?? templateGaps);
      _show(state, skillId, template, data);
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
    case Gui1Snapshot(:final stack):
      _replace(state, stack, gaps ?? templateGaps);
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
