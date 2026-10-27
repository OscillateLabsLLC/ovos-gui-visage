/// Any (namespace, page) without a widget degrades to the nearest page that can show its data (gui-1.md 6.5 and 8.5):
/// an `image` shows as the image page would (with `title` and `caption`), else `title` and `text` show as the text
/// page would. Data with none of these keys is dumped with the namespace and page name (SPEC 8.7): the main debugging
/// tool and the one place a card is allowed (SPEC 9).
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import 'image_frame_page.dart';
import 'page.dart';
import 'templates_model.dart';
import 'text_frame_page.dart';

const _mono = TextStyle(color: VisageColors.fg, fontSize: 12, fontFamily: 'Menlo', height: 1.3);

/// The page the data degrades to, or null when it has nothing a text or image page reads.
Widget? degradedPage(Json data) {
  if (imageSource(data['image']) != null) return ImageFramePage(data: data);
  final (:title, :text) = textFrameModel(data);
  if (text.isNotEmpty) return TextFramePage(data: {'title': title, 'text': text});
  if (title.isNotEmpty) return TextFramePage(data: {'text': title});
  return null;
}

String describe(Object? value) => value is String ? value : const JsonEncoder.withIndent(' ').convert(value);

class FallbackPage extends StatelessWidget {
  const FallbackPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => FallbackPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) => degradedPage(data) ?? _dump();

  Widget _dump() {
    final keys = data.keys.toList()..sort();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: VisageColors.card, borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ctx.page, style: VisageText.fg(22, weight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(ctx.namespace, style: VisageText.muted(13)),
            const SizedBox(height: 14),
            for (final key in keys) ...[
              Text(key, style: VisageText.base.copyWith(color: VisageColors.accent, fontSize: 13)),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 6),
                child: Text(describe(data[key]), style: _mono),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
