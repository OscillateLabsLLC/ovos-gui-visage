import 'package:flutter/material.dart';

import 'attention.dart';
import 'face/face.dart';
import 'face/face_badge.dart';
import 'face/face_theme.dart';

const _dimBg = Color(0xEB05070A);
const _badgeHeight = 104.0;
const _badgeGap = 7.0;

/// Content pages keep this much of the bottom free for the badge (SPEC 5.3: badge plus a 7 px gap above and below).
const attentionStrip = _badgeHeight + 2 * _badgeGap;

/// The collapsed peek window: the resting badge alone in a square frame; a tap expands it for a while.
class PeekBadge extends StatelessWidget {
  const PeekBadge({super.key, required this.face, required this.onTap});

  final FaceController face;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: FittedBox(
        child: SizedBox.square(
          dimension: frameWidth,
          child: FaceBadge(controller: face),
        ),
      ),
    );
  }
}

/// The face over the page: full and dimming over idle, else scaled into a disc at the bottom centre (SPEC 5.3).
class AttentionOverlay extends StatelessWidget {
  const AttentionOverlay({super.key, required this.attention, required this.face});

  final Attention attention;
  final FaceController face;

  @override
  Widget build(BuildContext context) {
    final geometry = face.theme.geometry;
    final scale = _badgeHeight / (2 * geometry.badgeRadius);
    final badgeCentre = Offset(frameWidth / 2, frameHeight - _badgeGap - _badgeHeight / 2);
    final shift = attention.compact ? badgeCentre - geometry.centre : Offset.zero;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: attention.shown ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: attention.compact ? Colors.transparent : _dimBg,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(shift.dx, shift.dy, 0)
              ..translateByDouble(geometry.centre.dx, geometry.centre.dy, 0, 1)
              ..scaleByDouble(attention.compact ? scale : 1, attention.compact ? scale : 1, 1, 1)
              ..translateByDouble(-geometry.centre.dx, -geometry.centre.dy, 0, 1),
            child: BadgeFace(controller: face, compact: attention.compact),
          ),
        ),
      ),
    );
  }
}
