import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/template_names.dart';

const matrixPath = 'docs/GUI1_CONFORMANCE.md';
const statuses = {'none', 'partial', 'done'};
const _columns = ['Item', 'Spec reference', 'Status', 'Visage files', 'Test', 'Notes'];
final _testPath = RegExp(r'`(test/[^`]+)`');

/// The adapter half of a clause cites the adapter's own tests (`ovos-gui-plugin-visage/test/...`); they name a test but
/// live in another repository, so their files are not checked here.
final _adapterTest = RegExp(r'`ovos-gui-plugin-visage/test/[^`]+`');

typedef Row = ({String item, String status, List<String> tests, int adapterTests});

List<String> cells(String line) => line.trim().split('|').skip(1).toList()..removeLast();

bool isDataRow(List<String> row) =>
    row.length == _columns.length && row.first.trim() != _columns.first && !row.first.trim().startsWith('---');

Row parseRow(List<String> row) => (
  item: row[0].trim().replaceAll('`', ''),
  status: row[2].trim(),
  tests: [for (final m in _testPath.allMatches(row[4])) m.group(1)!],
  adapterTests: _adapterTest.allMatches(row[4]).length,
);

List<Row> parseMatrix(String markdown) => [
  for (final line in markdown.split('\n'))
    if (line.trimLeft().startsWith('|') && isDataRow(cells(line))) parseRow(cells(line)),
];

void main() {
  final rows = parseMatrix(File(matrixPath).readAsStringSync());

  test('the matrix parses into rows', () {
    expect(rows.length, greaterThan(specTemplates.length));
  });

  test('every spec and companion template has exactly one row', () {
    final items = rows.map((r) => r.item).toList();
    for (final template in {...specTemplates, ...companionTemplates}) {
      expect(items.where((i) => i == template), hasLength(1), reason: '$template in $matrixPath');
    }
  });

  test('every status is none, partial or done', () {
    for (final row in rows) {
      expect(statuses, contains(row.status), reason: row.item);
    }
  });

  test('a done row names a test, of Visage or of the adapter', () {
    for (final row in rows.where((r) => r.status == 'done')) {
      expect(row.tests.length + row.adapterTests, isPositive, reason: row.item);
    }
  });

  test('every named test file exists', () {
    for (final row in rows) {
      for (final path in row.tests) {
        expect(File(path).existsSync(), isTrue, reason: '${row.item}: $path');
      }
    }
  });

  test('the parser drops header and separator rows and reads the test column', () {
    const sample = '''
| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| `SYSTEM_x` | gui-1.md 1 | done | `lib/a.dart` | `test/a_test.dart`, `ovos-gui-plugin-visage/test/test_a.py::test_b` | n |
| short | row |''';
    final parsed = parseMatrix(sample);
    expect(parsed.map((r) => (r.item, r.status)), [('SYSTEM_x', 'done')]);
    expect(parsed.single.tests, ['test/a_test.dart']);
    expect(parsed.single.adapterTests, 1);
  });
}
