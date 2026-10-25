/// SYSTEM_table (gui-1.md §3.4, line 231): the muted title, a header row in the muted uppercase of template titles
/// over an accent rule, then the rows with a faint rule between them. Columns share the width equally; cells wrap,
/// and the rows scroll.
library;

import 'package:flutter/material.dart';

import '../json.dart';
import '../theme.dart';
import 'content_models.dart';
import 'page.dart';
import 'template_text.dart';

const emptyTable = 'No rows';
const _cellPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 10);
const _rowRule = BorderSide(color: VisageColors.card);
const _headerRule = BorderSide(color: VisageColors.accentDim, width: 2);

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
        if (title.isNotEmpty) ...[TemplateTitle(title), const SizedBox(height: 14)],
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
    decoration: BoxDecoration(border: Border(bottom: header ? _headerRule : _rowRule)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cell in cells)
          Expanded(
            child: Padding(
              padding: _cellPadding,
              child: Text(header ? cell.toUpperCase() : cell, style: header ? templateTitleStyle : VisageText.fg(18)),
            ),
          ),
      ],
    ),
  );
}
