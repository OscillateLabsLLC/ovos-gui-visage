/// What a step between pages and a press on a page do to the shown namespace, on either protocol. Pure apart from the
/// two callbacks, so `ScreenInput` stays wiring.
library;

import 'pages/page_pager.dart';
import 'protocol/gui_events.dart';
import 'state/gui_state.dart';

/// Asks the GUI service for entry `page` of `namespace` (`GuiLink.requestFocus`).
typedef RequestFocus = bool Function(String namespace, int page);

/// A swipe, an arrow key or a chevron, [delta] pages on. On legacy the page changes here and the screen then reports
/// the new focus: true when it changed. On GUI-1 with a known entry the step is only a `focus` request, and the
/// service's next `template` frame, with its new `index`, moves the pager: false. Without a known entry the pager holds
/// one page, so there is nothing to step to.
bool stepPage(GuiState state, int delta, RequestFocus requestFocus) {
  final target = state.current();
  if (target == null) return false;
  final ns = state.namespace(target.namespace);
  final next = pageStep(ns.position.index, ns.position.count, delta);
  if (next == null) return false;
  if (ns.gui1Entry == null) return state.focusPage(target.namespace, next);
  requestFocus(target.namespace, next);
  return false;
}

/// A press on the page. GUI-1 with a known entry: a `focus` on the current entry, which only restarts the namespace's
/// timer. Otherwise the legacy use report, which GUI-1 without an entry refuses and reports once (`GuiLink.send`).
void touchPage(GuiState state, RequestFocus requestFocus, bool Function(Json message) sendGui) {
  final target = state.current();
  if (target == null) return;
  final entry = state.namespace(target.namespace).gui1Entry;
  if (entry == null) {
    sendGui(interactionMessage(target.namespace));
  } else {
    requestFocus(target.namespace, entry.index);
  }
}
