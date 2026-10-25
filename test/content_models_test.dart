import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/content_models.dart';
import 'package:ovos_gui_visage/pages/template_keys.dart';

import 'faults.dart';

const png = 'data:image/png;base64,iVBORw0KGgo=';

/// Runs [read] and returns its result with the report lines it made.
Future<(T, List<String>)> reported<T>(T Function() read) async {
  late T result;
  final faults = await collectFaults(() async => result = read());
  return (result, [for (final f in faults) '${f.context?.toDescription()}: ${f.exceptionAsString()}']);
}

void main() {
  setUp(forgetReportedKeys);

  group('template keys', () {
    test('an http(s) URL and a data:image URI are images; a bare path is reported (§3.5)', () async {
      final (images, faults) = await reported(
        () => [
          for (final v in ['https://x/a.png', 'HTTP://x/a.png', png, '/home/me/a.png', 'data:text/plain,hi', null])
            readImage('SYSTEM_list', {'image': v}, 'image'),
        ],
      );
      expect(images, ['https://x/a.png', 'HTTP://x/a.png', png, null, null, null]);
      expect(faults, hasLength(2));
      expect(faults.first, allOf(contains('SYSTEM_list data'), contains('/home/me/a.png'), contains('§3.5')));
    });

    test('the same fault is reported once', () async {
      final (_, faults) = await reported(() => [for (var i = 0; i < 3; i++) errorModel(const {})]);
      expect(faults, ['SYSTEM_error data: FormatException: label is required']);
    });
  });

  group('SYSTEM_error', () {
    test('label and detail', () async {
      final (model, faults) = await reported(() => errorModel(const {'label': 'No network', 'detail': 'Wi-Fi is off'}));
      expect(model, (label: 'No network', detail: 'Wi-Fi is off'));
      expect(faults, isEmpty);
    });

    test('a missing detail is no fault', () async {
      final (model, faults) = await reported(() => errorModel(const {'label': 'No network'}));
      expect([model.detail, faults], ['', isEmpty]);
    });

    test('a missing label is reported and the generic label shows', () async {
      final (model, faults) = await reported(() => errorModel(const {'detail': 'Wi-Fi is off'}));
      expect(model, (label: errorWithoutLabel, detail: 'Wi-Fi is off'));
      expect(faults.single, contains('label is required'));
    });

    test('a number label is reported and shown as text; an object detail is reported and dropped', () async {
      final (model, faults) = await reported(
        () => errorModel(const {
          'label': 404,
          'detail': {'a': 1},
        }),
      );
      expect(model, (label: '404', detail: ''));
      expect(faults, [contains('label must be a string, got int 404'), contains('detail must be a string')]);
    });
  });

  group('SYSTEM_list', () {
    test('title and items with optional subtitle and image', () async {
      final (model, faults) = await reported(
        () => listModel({
          'title': 'Groceries',
          'items': [
            {'title': 'Eggs', 'subtitle': 'A dozen', 'image': png},
            {'title': 'Milk'},
          ],
        }),
      );
      expect(model.title, 'Groceries');
      expect(model.items, [(title: 'Eggs', subtitle: 'A dozen', image: png), (title: 'Milk', subtitle: '', image: null)]);
      expect(faults, isEmpty);
    });

    test('no title and no items is an empty list, no fault', () async {
      final (model, faults) = await reported(() => listModel(const {}));
      expect([model.title, model.items, faults], ['', isEmpty, isEmpty]);
    });

    test('a bare path image is reported and the item keeps its text', () async {
      final (model, faults) = await reported(
        () => listModel({
          'items': [
            {'title': 'Eggs', 'image': '/tmp/eggs.png'},
          ],
        }),
      );
      expect(model.items, [(title: 'Eggs', subtitle: '', image: null)]);
      expect(faults.single, contains('image must be an http(s) URL or a data:image URI'));
    });

    test('an item without a title shows its subtitle; one with neither and a non-object are dropped', () async {
      final (model, faults) = await reported(
        () => listModel({
          'items': [
            {'subtitle': 'Only this'},
            {'image': png},
            'Eggs',
          ],
        }),
      );
      expect(model.items, [(title: 'Only this', subtitle: '', image: null)]);
      expect(faults, [contains('items[2] must be an object, got String Eggs'), contains('title is required')]);
    });

    test('items that are not an array are reported', () async {
      final (model, faults) = await reported(() => listModel(const {'items': 'Eggs, milk'}));
      expect(model.items, isEmpty);
      expect(faults.single, contains('items must be an array'));
    });
  });

  group('SYSTEM_grid', () {
    test('tiles with and without a title', () async {
      final (model, faults) = await reported(
        () => gridModel({
          'title': 'Albums',
          'items': [
            {'image': png, 'title': 'Blue Train'},
            {'image': png},
          ],
        }),
      );
      expect(model.tiles, [(image: png, title: 'Blue Train'), (image: png, title: '')]);
      expect([model.title, faults], ['Albums', isEmpty]);
    });

    test('a tile without an image is reported and keeps its title; one with nothing is dropped', () async {
      final (model, faults) = await reported(
        () => gridModel({
          'items': [
            {'title': 'Blue Train'},
            {'image': 'covers/a.jpg'},
          ],
        }),
      );
      expect(model.tiles, [(image: null, title: 'Blue Train')]);
      expect(faults, [contains('image is required'), contains('covers/a.jpg')]);
    });

    test('columns: tiles of at least 180 px, one to six', () {
      expect(
        [
          for (final w in [100.0, 375.0, 376.0, 432.0, 572.0, 800.0, 4000.0]) gridColumns(w),
        ],
        [1, 1, 2, 2, 3, 4, 6],
      );
    });
  });

  group('SYSTEM_table', () {
    Json table(Object? rows, {Object? columns = const ['A', 'B']}) => {'title': 'T', 'columns': columns, 'rows': rows};

    test('columns and rows; numbers and booleans show as text, null as empty', () async {
      final (model, faults) = await reported(
        () => tableModel(
          table([
            ['x', 1],
            [true, null],
          ]),
        ),
      );
      expect(
        [model.title, model.columns, model.rows],
        [
          'T',
          ['A', 'B'],
          [
            ['x', '1'],
            ['true', ''],
          ],
        ],
      );
      expect(faults, isEmpty);
    });

    test('a short row is padded and a long one truncated, each reported', () async {
      final (model, faults) = await reported(
        () => tableModel(
          table([
            ['x'],
            ['y', 'z', 'extra'],
          ]),
        ),
      );
      expect(model.rows, [
        ['x', ''],
        ['y', 'z'],
      ]);
      expect(faults, [contains('rows[0] has 1 cells for 2 columns'), contains('rows[1] has 3 cells for 2 columns')]);
    });

    test('without columns: reported, no header, as wide as the widest row', () async {
      final (model, faults) = await reported(
        () => tableModel(
          table([
            ['x'],
            ['y', 'z'],
          ], columns: null),
        ),
      );
      expect(model.columns, isEmpty);
      expect(model.rows, [
        ['x', ''],
        ['y', 'z'],
      ]);
      expect(faults.single, contains('columns is required'));
    });

    test('without rows: reported, the header alone; a non-array row and an object cell are reported', () async {
      final (empty, missing) = await reported(() => tableModel(table(null)));
      expect(
        [empty.columns, empty.rows],
        [
          ['A', 'B'],
          isEmpty,
        ],
      );
      expect(missing.single, contains('rows is required'));
      final (model, faults) = await reported(
        () => tableModel(
          table([
            'x',
            [
              {'k': 1},
              'b',
            ],
          ]),
        ),
      );
      expect(model.rows, [
        ['', 'b'],
      ]);
      expect(faults, [contains('rows[0] must be an array'), contains('rows[1][0] must be a string, number or boolean')]);
    });
  });
}
