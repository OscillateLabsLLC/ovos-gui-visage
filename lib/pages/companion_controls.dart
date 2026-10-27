/// The answer controls of the interactive companions (companions_model.dart): plain labelled buttons, finger sized,
/// white on the dark fills so the label keeps its contrast (docs/DESIGN.md, Glanceability).
library;

import 'package:flutter/material.dart';

import '../theme.dart';

const answerCirclePx = 148.0;
const choiceRowPx = 64.0;

/// A round answer button: [primary] takes the dim accent, the other the card fill.
class AnswerCircle extends StatelessWidget {
  const AnswerCircle({super.key, required this.label, required this.onPressed, this.primary = false});

  final String label;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: answerCirclePx,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        backgroundColor: primary ? VisageColors.accentDim : VisageColors.card,
        foregroundColor: VisageColors.fg,
        textStyle: VisageText.fg(26, weight: FontWeight.w500),
      ),
      child: Text(label, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
    ),
  );
}

/// A full-width choice: an optional round thumbnail, then the label.
class ChoiceButton extends StatelessWidget {
  const ChoiceButton({super.key, required this.label, required this.onPressed, this.thumbnail});

  final String label;
  final VoidCallback onPressed;
  final Widget? thumbnail;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(choiceRowPx),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      backgroundColor: VisageColors.card,
      foregroundColor: VisageColors.fg,
      textStyle: VisageText.fg(24),
    ),
    child: Row(
      spacing: 16,
      children: [
        if (thumbnail != null)
          ClipOval(
            child: SizedBox.square(dimension: choiceRowPx - 16, child: thumbnail),
          ),
        Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
