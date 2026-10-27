/// SYSTEM_table (gui-1.md 3.4 Catalogue): the template title, a header row in the muted uppercase of template titles,
/// then the rows as plain stacked text with a thin divider between them. Columns share the width equally; cells wrap
/// rather than shrink, and the rows scroll. Nothing moves.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import 'content_models.dart';
import 'page.dart';
import 'template_text.dart';

const emptyTable = 'No rows';
const _cellPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 10);

/// The faint hairline the design allows between rows (docs/DESIGN.md, Vocabulary); width 0 is Flutter's hairline.
const _divider = BorderSide(color: Color(0x24FFFFFF), width: 0);
const _titleGapPx = 14.0;

class TablePage extends StatelessWidget {
  const TablePage({super.key, required this.data});

  static Widget page(Json data, PageContext ctx) => TablePage(data: data);

  final Json data;

  @override
  Widget build(BuildContext context) {
    final (:title, :columns, :rows) = tableModel(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[TemplateTitle(title), const SizedBox(height: _titleGapPx)],
        if (columns.isNotEmpty) _line(columns, header: true),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: TemplateHint(emptyTable))
              : SingleChildScrollView(child: Column(children: [for (final row in rows) _line(row)])),
        ),
      ],
    );
  }

  Widget _line(List<String> cells, {bool header = false}) => DecoratedBox(
    decoration: const BoxDecoration(border: Border(bottom: _divider)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cell in cells)
          Expanded(
            child: Padding(
              padding: _cellPadding,
              child: Text(header ? cell.toUpperCase() : cell, style: header ? templateTitleStyle : VisageText.fg(20)),
            ),
          ),
      ],
    ),
  );
}
