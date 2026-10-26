/// What the user does to the screen besides the face: the in-window menu, the command box, the stored notification
/// list, moving between pages and
/// the use reports that keep a page from timing out. Each keeps a peeking widget open while it is up.
library;

import 'package:flutter/foundation.dart';

import 'page_moves.dart';
import 'pages/inner_pager.dart';
import 'protocol/core_bus.dart';
import 'protocol/utterance.dart';
import 'state/gui_state.dart';
import 'widgets/command_box.dart';
import 'widgets/notification_list.dart';
import 'window/peek.dart';
import 'window/window_menu.dart';
import 'window/window_remote.dart';

const menuHold = 'menu';
const commandHold = 'command';
const notificationsHold = 'notifications';

class ScreenInput {
  ScreenInput({
    required this.state,
    required this.bus,
    required this.sendGui,
    required this.requestFocus,
    required this.peek,
    required this.window,
    required this.dispatchMenu,
    required this.onChanged,
    required this.storage,
    this.lang,
  });

  final GuiState state;
  final CoreBus bus;
  final bool Function(Json message) sendGui;

  /// Asks the GUI service for another entry of a namespace (`GuiLink.requestFocus`).
  final bool Function(String namespace, int page) requestFocus;
  final PeekController peek;
  final WindowRemote window;
  final void Function(String id) dispatchMenu;

  /// The screen rebuilds: a page was stepped to, or the command box opened or closed.
  final VoidCallback onChanged;

  /// The WidgetManager's stored notifications, which the notification list shows.
  final ValueListenable<List<Json>> storage;
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

  late final NotificationListController notificationList = NotificationListController(
    bus: bus,
    storage: storage,
    onOpenChanged: (open) {
      peek.hold(open, by: notificationsHold);
      onChanged();
    },
  );

  /// The list belongs to the homescreen, as idle.qml's popup did: another page coming up closes it.
  void syncNotificationList() {
    if (state.current()?.namespace != state.idleNamespace) notificationList.close();
  }

  /// Escape closes the menu, else the notification list.
  bool dismiss() => menu.dismiss() || notificationList.dismiss();

  /// The menu's "Type a command…", from any host: a hidden window comes back first.
  void typeCommand() {
    if (!window.visible) window.setVisible(true);
    commands.open();
  }

  /// The inner pages of the page on screen, a long text's (pages/inner_pager.dart).
  final innerPages = InnerPagerSlot();

  /// A swipe, an arrow key or a chevron: the inner pages while they can step that way, else the skill's (`stepPage`).
  void step(int delta) {
    if (innerPages.step(delta)) return;
    if (stepPage(state, delta, requestFocus)) onChanged();
  }

  /// A press on the page (`touchPage`).
  void interact() => touchPage(state, requestFocus, sendGui);

  void dispose() {
    menu.dispose();
    commands.dispose();
    notificationList.dispose();
    innerPages.dispose();
  }
}
