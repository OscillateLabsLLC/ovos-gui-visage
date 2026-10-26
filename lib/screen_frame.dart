/// The 480 x 800 frame the screen scales into the window: the page with its pager, the attention face, captions, the
/// status row (offline, outcome, volume, notifications), the command box and its homescreen button, and try-on mode on top
/// (it owns the gestures while active).
library;

import 'package:flutter/material.dart';

import 'attention.dart';
import 'captions.dart';
import 'face/face.dart';
import 'face/face_remote.dart';
import 'face/face_scope.dart';
import 'face/face_theme.dart';
import 'face/try_on.dart';
import 'outcome.dart';
import 'pages/page.dart';
import 'pages/page_pager.dart';
import 'pages/resting_model.dart';
import 'pages/router.dart';
import 'protocol/wire_protocol.dart';
import 'screen_input.dart';
import 'shell_overlays.dart';
import 'state/gui_state.dart';
import 'theme.dart';
import 'volume.dart';
import 'widgets/caption_strip.dart';
import 'widgets/command_box.dart';
import 'widgets/notification_actions.dart';
import 'widgets/notification_list.dart';
import 'widgets/notification_list_panel.dart';
import 'widgets/notification_popups.dart';
import 'widgets/notification_stack.dart';
import 'widgets/offline_pill.dart';
import 'widgets/outcome_pill.dart';
import 'widgets/volume_indicator.dart';

const _pagePadding = 32.0;
const _sidePadding = 24.0;

/// What the frame needs from the screen; one object so the screen's build stays a line.
class FrameParts {
  const FrameParts({
    required this.state,
    required this.attention,
    required this.face,
    required this.remote,
    required this.commands,
    required this.send,
    required this.connected,
    required this.protocol,
    required this.captions,
    required this.outcome,
    required this.volume,
    required this.popups,
    required this.notifications,
    required this.notificationList,
    required this.listShown,
    required this.expanded,
    required this.kiosk,
    required this.typeOnHome,
    required this.input,
    required this.onTryOn,
  });

  final GuiState state;
  final Attention attention;
  final FaceController face;
  final FaceRemote remote;
  final CommandBoxController commands;
  final GuiSend send;
  final bool connected;

  /// What the GUI connection speaks; on GUI-1 an empty stack shows Visage's resting page.
  final ChosenProtocol? protocol;

  /// Null when captions are turned off.
  final Captions? captions;
  final OutcomeModel outcome;
  final VolumeModel volume;
  final NotificationPopups popups;

  /// What a tap on a popup or its close button sends.
  final NotificationActions notifications;

  /// The stored notifications, which the homescreen's count badge opens over the page.
  final NotificationListController notificationList;
  final bool listShown;
  final bool expanded;
  final bool kiosk;

  /// Window and kiosk mode put a keyboard button on the homescreen.
  final bool typeOnHome;

  /// Steps between pages and reports use of the page; holds the inner pages of the page on screen.
  final ScreenInput input;
  final void Function(bool active) onTryOn;
}

class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.parts});

  final FrameParts parts;

  @override
  Widget build(BuildContext context) {
    final p = parts;
    return SizedBox(
      width: frameWidth,
      height: frameHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: FaceScope(
          controller: p.face,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: VisageColors.pageBg)),
              Positioned.fill(child: _page()),
              if (p.listShown) NotificationListPanel(items: p.notificationList.items, controller: p.notificationList),
              AttentionOverlay(attention: p.attention, face: p.face),
              if (p.captions case final captions?) CaptionStrip(captions: captions, compact: p.attention.compact),
              _topStatus(),
              ..._commandParts(),
              FaceTryOn(controller: p.face, remote: p.remote, enabled: p.expanded, onActive: p.onTryOn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _page() {
    final target = parts.state.current();
    final position = target == null ? (index: 0, count: 0) : parts.state.namespace(target.namespace).position;
    final bottom = parts.attention.compact ? attentionStrip : _pagePadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(_sidePadding, _pagePadding, _sidePadding, bottom),
      child: PagePager(
        index: position.index,
        count: position.count,
        onStep: parts.input.step,
        onInteract: parts.input.interact,
        inner: parts.input.innerPages,
        chevrons: parts.kiosk,
        child: PageHost(state: parts.state, send: parts.send, notifications: parts.notificationList, protocol: parts.protocol),
      ),
    );
  }

  Widget _topStatus() => TopStatus(
    interactive: parts.popups.all.isEmpty
        ? null
        : NotificationStack(popups: parts.popups.all, onTap: parts.notifications.act, onClose: parts.notifications.close),
    children: [
      if (!parts.connected) const OfflinePill(),
      OutcomePill(outcome: parts.outcome.showing),
      VolumeIndicator(showing: parts.volume.showing, level: parts.volume.level, muted: parts.volume.muted),
    ],
  );

  List<Widget> _commandParts() {
    final commands = parts.commands;
    if (commands.isOpen) {
      return [Positioned(left: 16, right: 16, bottom: 20, child: CommandBox(controller: commands))];
    }
    final target = parts.state.current();
    final home =
        showsResting(parts.state, parts.protocol) || (target != null && !isContentPage(target, parts.state.idleNamespace));
    if (!parts.typeOnHome || !home) return const [];
    return [Positioned(right: 20, bottom: 20, child: CommandButton(onPressed: commands.open))];
  }
}
