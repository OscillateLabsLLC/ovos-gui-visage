/// The notification popups under the status pills: each slides down into place, with a dot in the shell's colour for
/// its style. More than [maxPopupsShown] collapse into a "+n more" line, so the stack never hides the page.
library;

import 'package:flutter/material.dart';

import '../face/face_theme.dart';
import '../theme.dart';
import 'notification_popups.dart';

const popupSlide = Duration(milliseconds: 280);

/// Wide enough for two lines of text, narrow enough to clear the idle page's count badge in the top-right corner.
const popupSide = 56.0;
const _popupBackground = Color(0xF0141B24);

/// ovos-shell's styleAreaNotifier colours.
const popupStyleColours = {
  'info': Color(0xFF3498DB),
  'warning': Color(0xFFCF850F),
  'success': Color(0xFF00BC8C),
  'error': Color(0xFFE74C3C),
};

Color popupColour(String style) => popupStyleColours[style] ?? popupStyleColours['info']!;

class NotificationStack extends StatelessWidget {
  const NotificationStack({super.key, required this.popups});

  final List<Popup> popups;

  @override
  Widget build(BuildContext context) {
    final shown = popups.take(maxPopupsShown).toList();
    final hidden = popups.length - shown.length;
    return SizedBox(
      width: frameWidth - 2 * popupSide,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          for (final popup in shown)
            _SlideIn(
              key: ValueKey(popup.id),
              child: PopupCard(popup: popup),
            ),
          if (hidden > 0) Text('+$hidden more', style: VisageText.muted(13)),
        ],
      ),
    );
  }
}

class PopupCard extends StatelessWidget {
  const PopupCard({super.key, required this.popup});

  final Popup popup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: _popupBackground, borderRadius: BorderRadius.circular(18)),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: popupColour(popup.style), shape: BoxShape.circle),
          ),
          Expanded(child: Text(popup.text, style: VisageText.fg(17, height: 1.25))),
        ],
      ),
    );
  }
}

class _SlideIn extends StatelessWidget {
  const _SlideIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: popupSlide,
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, -24 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
