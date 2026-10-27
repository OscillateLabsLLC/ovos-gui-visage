/// The caption strip at the bottom of the frame: the heard line muted above the reply. It sits above the badge strip
/// on a content page, never over the badge, and lives inside the frame, so the collapsed peek badge never shows it.
/// Long text wraps and shrinks to fit the strip; nothing is cut off.
library;

import 'package:flutter/material.dart';

import '../captions.dart';
import '../face/face_theme.dart';
import '../shell_overlays.dart';
import '../theme.dart';

const captionSide = 24.0;
const captionBottomGap = 28.0;
const captionMaxHeight = 260.0;
const captionFade = Duration(milliseconds: 400);
const _scrim = Color(0xD905070A);

class CaptionStrip extends StatelessWidget {
  const CaptionStrip({super.key, required this.captions, required this.compact});

  final Captions captions;

  /// A content page keeps the bottom for the face badge, so the strip sits above it.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: compact ? attentionStrip : 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: captions.visible ? 1 : 0,
          duration: captionFade,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x0005070A), _scrim],
                stops: [0, 0.35],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(captionSide, 28, captionSide, compact ? 4 : captionBottomGap),
              child: _text(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _text() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: captionMaxHeight),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: frameWidth - 2 * captionSide,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (captions.heard.isNotEmpty)
                Text(captions.heard, key: const Key('caption-heard'), textAlign: TextAlign.center, style: _heardStyle),
              if (captions.heard.isNotEmpty && captions.reply.isNotEmpty) const SizedBox(height: 8),
              if (captions.reply.isNotEmpty)
                Text(captions.reply, key: const Key('caption-reply'), textAlign: TextAlign.center, style: _replyStyle),
            ],
          ),
        ),
      ),
    );
  }
}

/// The heard line is quieter than the reply by colour alone: small italic text was unreadable in a half-size window.
final _heardStyle = VisageText.muted(22);
final _replyStyle = VisageText.fg(24, height: 1.25);
