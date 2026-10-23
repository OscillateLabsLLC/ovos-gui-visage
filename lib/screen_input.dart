/// What the user does to the screen besides the face: moving between pages and the use reports that keep a page from
/// timing out.
library;

import 'package:flutter/foundation.dart';

import 'pages/page_pager.dart';
import 'protocol/gui_events.dart';
import 'state/gui_state.dart';

class ScreenInput {
  ScreenInput({required this.state, required this.sendGui, required this.onChanged});

  final GuiState state;
  final bool Function(Json message) sendGui;

  /// The screen rebuilds: a page was stepped to.
  final VoidCallback onChanged;

  /// A swipe, an arrow key or a chevron; the screen tells ovos-gui about the new focus as it does for any change.
  void step(int delta) {
    final target = state.current();
    if (target == null) return;
    final next = pageStep(target.index, state.namespace(target.namespace).pages.length, delta);
    if (next != null && state.focusPage(target.namespace, next)) onChanged();
  }

  void interact() {
    final target = state.current();
    if (target != null) sendGui(interactionMessage(target.namespace));
  }
}
