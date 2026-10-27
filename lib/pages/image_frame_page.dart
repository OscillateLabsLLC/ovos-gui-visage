/// SYSTEM_ImageFrame and SYSTEM_AnimatedImageFrame (SPEC 8.2): muted title, the image in a rounded frame honouring
/// fill and background_color, muted caption. Image.file plays GIF and WebP, so both templates share this page.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources/resources.dart';
import 'page.dart';
import 'reduced_motion.dart';
import 'template_names.dart';
import 'template_text.dart';
import 'templates_model.dart';

const unavailable = 'Image unavailable';

/// `#rgb`, `#rrggbb` or `#aarrggbb` from a skill, else transparent.
Color parseColor(String value) {
  var hex = value.trim().replaceFirst('#', '');
  if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
  if (hex.length == 6) hex = 'ff$hex';
  final argb = hex.length == 8 ? int.tryParse(hex, radix: 16) : null;
  return argb == null ? Colors.transparent : Color(argb);
}

class ImageFramePage extends StatelessWidget {
  const ImageFramePage({super.key, required this.data, this.gui1Template});

  static Widget page(Json data, PageContext ctx) =>
      ImageFramePage(data: data, gui1Template: ctx.gui1 ? canonicalTemplate(ctx.page) ?? ctx.page : null);

  final Json data;

  /// The template's name when the page came over GUI-1, whose image rules are stricter (`imageModel`).
  final String? gui1Template;

  @override
  Widget build(BuildContext context) {
    final model = imageModel(data, gui1Template: gui1Template);
    final image = imageFor(model.src, fit: model.fit);
    return Column(
      children: [
        if (model.title.isNotEmpty) ...[RiseOrStill(index: 0, child: TemplateTitle(model.title)), const SizedBox(height: 14)],
        Expanded(
          child: RiseOrStill(
            index: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ColoredBox(
                color: parseColor(model.background),
                child: SizedBox.expand(child: image ?? const Center(child: TemplateHint(unavailable))),
              ),
            ),
          ),
        ),
        if (model.caption.isNotEmpty) ...[const SizedBox(height: 14), RiseOrStill(index: 2, child: TemplateHint(model.caption))],
      ],
    );
  }
}
