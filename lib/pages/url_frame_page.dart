/// SYSTEM_UrlFrame (SPEC 8.2) without a webview (SCOPE: webviews are gated per platform, phase 4): the URL beside a
/// turning globe, the same chip ovos-visage shows for a site that refuses framing.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../resources.dart';
import '../theme.dart';
import '../widgets/circle.dart';
import 'page.dart';
import 'template_text.dart';
import 'templates_model.dart';

class UrlFramePage extends StatelessWidget {
  const UrlFramePage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => UrlFramePage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final model = urlModel(data);
    return StaggerEnter(
      gap: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Circle(size: 180, gradient: gradientFill, glow: const Glow(), ring: const Ring(), children: [icon('globe', size: 104)]),
        ),
        Text(model.url, textAlign: TextAlign.center, style: VisageText.fg(24)),
        TemplateHint(model.frameable ? 'no web view on this platform' : 'not a web address'),
      ],
    );
  }
}
