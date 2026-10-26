/// The stored notification list over the homescreen, in the popups' style: a dot in the shell's colour for each style,
/// the sender over the text, rows divided by hairlines rather than cards. A shell overlay, so it owns its keys while
/// it has the focus: the arrow keys move between the controls, Enter or Space presses one, Escape closes the list.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'notification_list.dart';
import 'notification_stack.dart';
import 'stored_notifications.dart';

const _panelBackground = Color(0xF505070A);
const _hairline = Color(0x24FFFFFF);
const listTitle = 'Notifications';
const emptyListText = 'Nothing kept yet';
const emptyListHint = 'Notices that time out or that you close come here.';

const _arrows = <ShortcutActivator, Intent>{
  SingleActivator(LogicalKeyboardKey.arrowUp): DirectionalFocusIntent(TraversalDirection.up),
  SingleActivator(LogicalKeyboardKey.arrowDown): DirectionalFocusIntent(TraversalDirection.down),
  SingleActivator(LogicalKeyboardKey.arrowLeft): DirectionalFocusIntent(TraversalDirection.left),
  SingleActivator(LogicalKeyboardKey.arrowRight): DirectionalFocusIntent(TraversalDirection.right),
};

class NotificationListPanel extends StatefulWidget {
  const NotificationListPanel({super.key, required this.items, required this.controller});

  final List<StoredNotification> items;
  final NotificationListController controller;

  @override
  State<NotificationListPanel> createState() => _NotificationListPanelState();
}

class _NotificationListPanelState extends State<NotificationListPanel> {
  final first = FocusNode(debugLabel: 'first stored notification');

  /// Asked for after the first frame, as the command box does: the window surface holds the focus until then. When the
  /// list goes, its focus scope hands the focus back to the surface.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => first.requestFocus());
  }

  @override
  void dispose() {
    first.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Positioned.fill(
      child: Shortcuts(
        shortcuts: _arrows,
        child: CallbackShortcuts(
          bindings: {const SingleActivator(LogicalKeyboardKey.escape): controller.close},
          child: FocusTraversalGroup(
            child: ColoredBox(
              color: _panelBackground,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(controller),
                    const SizedBox(height: 8),
                    Expanded(child: _list(controller)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(NotificationListController controller) => Row(
    children: [
      Expanded(
        child: Text(listTitle, style: VisageText.fg(28, weight: FontWeight.w300)),
      ),
      TextButton(
        onPressed: controller.clearAll,
        style: TextButton.styleFrom(foregroundColor: VisageColors.accent),
        child: Text('Clear all', style: VisageText.fg(17).copyWith(color: VisageColors.accent)),
      ),
      IconButton(
        tooltip: 'Close notifications',
        color: VisageColors.muted,
        onPressed: controller.close,
        icon: const Icon(Icons.close_rounded),
      ),
    ],
  );

  Widget _list(NotificationListController controller) => widget.items.isEmpty ? _empty() : _rows(controller);

  Widget _empty() => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emptyListText, style: VisageText.fg(22)),
        const SizedBox(height: 6),
        Text(emptyListHint, style: VisageText.muted(17)),
      ],
    ),
  );

  Widget _rows(NotificationListController controller) => ListView.separated(
    padding: EdgeInsets.zero,
    itemCount: widget.items.length,
    separatorBuilder: (_, _) => const Divider(height: 1, thickness: 1, color: _hairline),
    itemBuilder: (_, i) => StoredRow(item: widget.items[i], controller: controller, focus: i == 0 ? first : null),
  );
}

class StoredRow extends StatelessWidget {
  const StoredRow({super.key, required this.item, required this.controller, this.focus});

  final StoredNotification item;
  final NotificationListController controller;

  /// The first row's first control takes the focus when the list opens.
  final FocusNode? focus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: popupColour(item.style), shape: BoxShape.circle),
          ),
          Expanded(child: item.hasAction ? _actionable() : _words()),
          IconButton(
            tooltip: 'Clear notification',
            focusNode: item.hasAction ? null : focus,
            color: VisageColors.muted,
            onPressed: () => controller.clear(item),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _actionable() => InkWell(
    focusNode: focus,
    borderRadius: BorderRadius.circular(10),
    onTap: () => controller.act(item),
    child: Row(
      children: [
        Expanded(child: _words()),
        const Icon(Icons.chevron_right_rounded, color: VisageColors.muted),
      ],
    ),
  );

  Widget _words() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        if (item.sender.isNotEmpty) Text(item.sender, maxLines: 1, overflow: TextOverflow.ellipsis, style: VisageText.muted(13)),
        Text(item.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: VisageText.fg(17, height: 1.25)),
      ],
    ),
  );
}
