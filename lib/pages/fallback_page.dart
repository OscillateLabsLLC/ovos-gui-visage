/// Any (namespace, page) without a widget: namespace, page name and a dump of the session data (SPEC 8.7).
/// The main debugging tool and the one place a card is allowed (SPEC 9).
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import 'page.dart';

const _mono = TextStyle(color: VisageColors.fg, fontSize: 12, fontFamily: 'Menlo', height: 1.3);

String describe(Object? value) => value is String ? value : const JsonEncoder.withIndent(' ').convert(value);

class FallbackPage extends StatelessWidget {
  const FallbackPage({super.key, required this.data, required this.ctx});

  static Widget page(Json data, PageContext ctx) => FallbackPage(data: data, ctx: ctx);

  final Json data;
  final PageContext ctx;

  @override
  Widget build(BuildContext context) {
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
