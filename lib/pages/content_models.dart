/// View models for SYSTEM_error, SYSTEM_list, SYSTEM_grid and SYSTEM_table (gui-1.md 3.4 Catalogue).
/// Pure, except that malformed data is reported through template_keys.dart; every model still returns something the
/// page can render (gui-1.md 6.5 Capability and graceful degradation).
library;

import 'dart:math' as math;

import '../json.dart';
import 'template_keys.dart';

const errorTemplate = 'SYSTEM_error';
const listTemplate = 'SYSTEM_list';
const gridTemplate = 'SYSTEM_grid';
const tableTemplate = 'SYSTEM_table';

/// The label an error shows when it arrives without one.
const errorWithoutLabel = 'Something went wrong';

/// Grid tiles are never narrower than this, and the grid never has more than [maxGridColumns] columns.
const minTilePx = 180.0;
const maxGridColumns = 6;

/// `label` is required: without it the page shows [errorWithoutLabel]; a number or boolean label shows as its text.
({String label, String detail}) errorModel(Json data) {
  final label = readText(errorTemplate, data, 'label', required: true);
  return (label: label.isEmpty ? errorWithoutLabel : label, detail: readText(errorTemplate, data, 'detail'));
}

typedef ListItem = ({String title, String subtitle, String? image});

/// `items` is optional (the catalogue marks only the item's `title`); absent or not an array gives an empty list. An item
/// without `title` is reported and shows its subtitle in its place; one with neither is dropped.
({String title, List<ListItem> items}) systemListModel(Json data) {
  final items = readList(listTemplate, data, 'items') ?? const [];
  return (
    title: readText(listTemplate, data, 'title'),
    items: [...readItems(listTemplate, items, 'items').map(_listItem).nonNulls],
  );
}

ListItem? _listItem(Json item) {
  final title = readText(listTemplate, item, 'title', required: true);
  final subtitle = readText(listTemplate, item, 'subtitle');
  final image = readImage(listTemplate, item, 'image');
  if (title.isEmpty && subtitle.isEmpty) return null;
  return title.isEmpty ? (title: subtitle, subtitle: '', image: image) : (title: title, subtitle: subtitle, image: image);
}

typedef GridItem = ({String? image, String title});

/// `items` is optional as for the list. A tile without a usable `image` is reported and shows its title on a plain
/// tile; one with neither is dropped.
({String title, List<GridItem> tiles}) gridModel(Json data) {
  final items = readList(gridTemplate, data, 'items') ?? const [];
  return (title: readText(gridTemplate, data, 'title'), tiles: [...readItems(gridTemplate, items, 'items').map(_tile).nonNulls]);
}

GridItem? _tile(Json item) {
  final image = readImage(gridTemplate, item, 'image', required: true);
  final title = readText(gridTemplate, item, 'title');
  return image == null && title.isEmpty ? null : (image: image, title: title);
}

/// As many columns of at least [minTilePx] as fit in [width] with [gap] between them: one to [maxGridColumns].
int gridColumns(double width, {double gap = 16}) => ((width + gap) / (minTilePx + gap)).floor().clamp(1, maxGridColumns);

typedef TableModel = ({String title, List<String> columns, List<List<String>> rows});

/// `columns` and `rows` are required. A row shorter than `columns` is reported and padded with empty cells; a longer
/// one is reported and truncated to `columns`. Without `columns` the table has no header and is as wide as its widest
/// row. A cell is shown as its text; null is empty; an object or array cell is reported and shown empty.
TableModel tableModel(Json data) {
  final columns = [
    for (final (i, c) in (readList(tableTemplate, data, 'columns', required: true) ?? const []).indexed) _cell('columns[$i]', c),
  ];
  final raw = [for (final (i, r) in (readList(tableTemplate, data, 'rows', required: true) ?? const []).indexed) ?_row(i, r)];
  final width = columns.isNotEmpty ? columns.length : raw.fold(0, (w, r) => math.max(w, r.length));
  return (
    title: readText(tableTemplate, data, 'title'),
    columns: columns,
    rows: [for (final (i, r) in raw.indexed) _fit(i, r, width, columns.isNotEmpty)],
  );
}

List<String>? _row(int index, Object? row) {
  if (row is List) return [for (final (j, cell) in row.indexed) _cell('rows[$index][$j]', cell)];
  reportKey(tableTemplate, 'rows[$index]', 'must be an array, got ${row.runtimeType} $row');
  return null;
}

String _cell(String key, Object? cell) {
  if (cell == null) return '';
  if (cell is String || cell is num || cell is bool) return '$cell';
  reportKey(tableTemplate, key, 'must be a string, number or boolean, got ${cell.runtimeType} $cell');
  return '';
}

List<String> _fit(int index, List<String> row, int width, bool hasColumns) {
  if (row.length == width) return row;
  if (hasColumns) reportKey(tableTemplate, 'rows[$index]', 'has ${row.length} cells for $width columns');
  return row.length > width ? row.sublist(0, width) : [...row, for (var k = row.length; k < width; k++) ''];
}
