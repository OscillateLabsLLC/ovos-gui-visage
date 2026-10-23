/// The brief outcome of a voice turn as a status pill. Success takes the face's accent, so every
/// face theme expresses it in its own colour; cancelled is a neutral grey and failure the shell's warning red.
library;

import 'package:flutter/material.dart';

import '../face/face_palette.dart';
import '../face/face_scope.dart';
import '../outcome.dart';
import '../theme.dart';
import 'offline_pill.dart';

const outcomeFade = Duration(milliseconds: 250);
const _pillBackground = Color(0xE6141B24);

const outcomeLabels = {Outcome.success: 'Done', Outcome.cancelled: 'Cancelled', Outcome.failure: "Didn't work"};
const outcomeIcons = {
  Outcome.success: Icons.check_rounded,
  Outcome.cancelled: Icons.remove_rounded,
  Outcome.failure: Icons.close_rounded,
};

Color outcomeColour(Outcome outcome, FacePalette palette) => switch (outcome) {
  Outcome.success => palette.accent,
  Outcome.cancelled => VisageColors.muted,
  Outcome.failure => VisageColors.bad,
};

class OutcomePill extends StatelessWidget {
  const OutcomePill({super.key, required this.outcome});

  final Outcome? outcome;

  @override
  Widget build(BuildContext context) {
    final palette = FaceScope.maybeOf(context)?.theme.palette ?? FacePalette.visage;
    final shown = outcome;
    return AnimatedSwitcher(
      duration: outcomeFade,
      child: shown == null
          ? const SizedBox.shrink()
          : StatusPill(
              key: ValueKey(shown),
              label: outcomeLabels[shown]!,
              icon: outcomeIcons[shown],
              colour: outcomeColour(shown, palette),
              background: _pillBackground,
            ),
    );
  }
}
