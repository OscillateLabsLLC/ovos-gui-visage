/// Shared text pieces of the SYSTEM_* templates (templates.css): the small uppercase title, the hint, the label.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

final templateTitleStyle = VisageText.muted(15).copyWith(letterSpacing: 1);

class TemplateTitle extends StatelessWidget {
  const TemplateTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Text(title.toUpperCase(), textAlign: TextAlign.center, style: templateTitleStyle);
}

class TemplateHint extends StatelessWidget {
  const TemplateHint(this.hint, {super.key});

  final String hint;

  @override
  Widget build(BuildContext context) => Text(hint, textAlign: TextAlign.center, style: VisageText.muted(14));
}

class TemplateLabel extends StatelessWidget {
  const TemplateLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 400),
    child: Text(label, textAlign: TextAlign.center, style: VisageText.fg(22)),
  );
}

/// Laid-out height of [text] at [style] within [maxWidth].
double measureText(String text, TextStyle style, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
  return painter.height;
}
