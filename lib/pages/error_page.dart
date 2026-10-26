/// SYSTEM_error (gui-1.md 3.4 Catalogue): a chip-sized gradient circle with an exclamation mark in the failure red,
/// a red-tinted glow that blooms once as the error arrives and then breathes, the label beneath and the detail muted
/// under it. With reduced motion the halo stands still.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'content_models.dart';
import 'loading_page.dart' show lottieChipPx;
import 'page.dart';
import 'reduced_motion.dart';
import 'template_text.dart';

const errorMark = '!';
const _badSoft = Color(0x2EFF5C5C);
const _badDim = Color(0x66FF5C5C);

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => ErrorPage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:label, :detail) = errorModel(data);
    return StaggerOrStill(
      children: [
        Circle(
          size: lottieChipPx,
          gradient: gradientFill,
          glow: const Glow(colour: _badSoft, bloom: true),
          ring: const Ring(track: _badDim, value: VisageColors.bad),
          children: [
            Text(
              errorMark,
              style: VisageText.fg(96, weight: FontWeight.w300).copyWith(color: VisageColors.bad),
            ),
          ],
        ),
        TemplateLabel(label),
        if (detail.isNotEmpty) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: TemplateHint(detail)),
      ],
    );
  }
}
