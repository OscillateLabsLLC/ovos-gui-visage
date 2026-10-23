/// What the user does to the screen besides the face: the in-window menu, the command box, moving between pages and
/// the use reports that keep a page from timing out. Each keeps a peeking widget open while it is up.
library;

import 'package:flutter/foundation.dart';

import 'pages/page_pager.dart';
import 'protocol/core_bus.dart';
import 'protocol/gui_events.dart';
import 'protocol/utterance.dart';
import 'state/gui_state.dart';
import 'widgets/command_box.dart';
import 'window/peek.dart';
import 'window/window_menu.dart';
import 'window/window_remote.dart';

const menuHold = 'menu';
const commandHold = 'command';

class ScreenInput {
  ScreenInput({
    required this.state,
    required this.bus,
    required this.sendGui,
    required this.peek,
    required this.window,
    required this.dispatchMenu,
    required this.onChanged,
    this.lang,
  });

  final GuiState state;
  final CoreBus bus;
  final bool Function(Json message) sendGui;
  final PeekController peek;
  final WindowRemote window;
  final void Function(String id) dispatchMenu;

  /// The screen rebuilds: a page was stepped to, or the command box opened or closed.
  final VoidCallback onChanged;
  final String? lang;

  late final WindowMenuHost menu = WindowMenuHost(
    onSelected: dispatchMenu,
    canQuit: !kIsWeb,
    onOpenChanged: (open) => peek.hold(open, by: menuHold),
  );

  late final CommandBoxController commands = CommandBoxController(
    send: (text) => sendUtterance(bus, text, lang: lang),
    onOpenChanged: (open) {
      peek.hold(open, by: commandHold);
      onChanged();
    },
  );

  /// The menu's "Type a command…", from any host: a hidden window comes back first.
  void typeCommand() {
    if (!window.visible) window.setVisible(true);
    commands.open();
  }

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

  void dispose() {
    menu.dispose();
    commands.dispose();
  }
}
