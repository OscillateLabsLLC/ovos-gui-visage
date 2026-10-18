/// SYSTEM_HtmlFrame (SPEC 8.2): the skill's HTML in a web view where this platform has one (SCOPE: gated per
/// platform), else reduced to its text, readable on black, with scripts and styles dropped.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import '../widgets/web_frame.dart';
import 'page.dart';

final _dropBlocks = RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true);
final _breaks = RegExp(r'</(p|div|h[1-6]|li|tr|br)\s*>|<br\s*/?>', caseSensitive: false);
final _tags = RegExp(r'<[^>]+>');
final _blankLines = RegExp(r'\n{3,}');

/// Plain text from a fragment of HTML: block ends become line breaks, every other tag is removed.
String htmlToText(String html) {
  final text = html.replaceAll(_dropBlocks, '').replaceAll(_breaks, '\n').replaceAll(_tags, '');
  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(_blankLines, '\n\n')
      .trim();
}

class HtmlFramePage extends StatelessWidget {
  const HtmlFramePage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => HtmlFramePage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final html = text(data['html']);
    if (hasWebView) return WebFrame.html(html);
    return SingleChildScrollView(child: Text(htmlToText(html), style: VisageText.fg(20, height: 1.4)));
  }
}
