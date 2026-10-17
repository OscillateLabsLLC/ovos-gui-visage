/// SYSTEM_InputBox (SPEC 8.2), display-only: a glowing ring chip with a listening microphone (its sound waves
/// expand and fade as the icon's CSS did), the title and placeholder as a prompt beneath, confirm and exit as
/// muted hints. Nothing is clickable (SPEC 1).
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import '../widgets/motion_icon.dart';
import 'page.dart';
import 'template_text.dart';
import 'templates_model.dart';

class InputBoxPage extends StatelessWidget {
  const InputBoxPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => InputBoxPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final model = inputBoxModel(data);
    final hints = [model.confirm, model.exit].where((s) => s.isNotEmpty).join('  ·  ');
    return StaggerEnter(
      gap: 20,
      children: [
        Circle(
          size: 200,
          gradient: gradientFill,
          glow: const Glow(),
          ring: const Ring(),
          children: const [MotionIcon('mic', size: 110)],
        ),
        if (model.title.isNotEmpty) Text(model.title, textAlign: TextAlign.center, style: VisageText.fg(30)),
        if (model.placeholder.isNotEmpty)
          Text(
            model.placeholder,
            textAlign: TextAlign.center,
            style: VisageText.muted(22).copyWith(fontStyle: FontStyle.italic),
          ),
        if (hints.isNotEmpty) TemplateHint(hints),
      ],
    );
  }
}
