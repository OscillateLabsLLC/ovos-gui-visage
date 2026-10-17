// Port of tests/js/visemes.test.mjs.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/visemes.dart';

List<dynamic> recordedVisemes() {
  final lines = File('test/fixtures/corebus/visemes_what_time_is_it.jsonl').readAsLinesSync();
  final message = lines
      .where((l) => l.isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .firstWhere((m) => m['type'] == 'enclosure.mouth.viseme_list');
  return message['data']['visemes'] as List;
}

void main() {
  test('pairs are code plus cumulative end time', () {
    final visemes = [
      ['4', 0.35],
      ['0', 0.375],
      ['3', 0.4],
    ];
    expect(visemeAt(visemes, 0), 4);
    expect(visemeAt(visemes, 0.349), 4);
    expect(visemeAt(visemes, 0.35), 0);
    expect(visemeAt(visemes, 0.39), 3);
    expect(visemeAt(visemes, 0.4), isNull);
    expect(visemeAt(visemes, -0.1), isNull);
    expect(visemeAt([], 0), isNull);
  });

  test("recorded 'what time is it' list plays through and ends", () {
    final recorded = recordedVisemes();
    expect(recorded.length, 27);
    final ends = [for (final pair in recorded) (pair[1] as num).toDouble()];
    expect(ends, List.of(ends)..sort());
    expect(visemeAt(recorded, 0.1), 4);
    expect(visemeAt(recorded, 0.36), 0);
    final last = ends.last;
    expect(visemeAt(recorded, last - 0.001), int.parse(recorded.last[0] as String));
    expect(visemeAt(recorded, last), isNull);
    final seen = <int?>{};
    for (var t = 0.0; t < last; t += 0.01) {
      seen.add(visemeAt(recorded, t));
    }
    expect(seen.length, greaterThanOrEqualTo(3));
  });

  test('all seven shapes have identical point counts and differ', () {
    final shapes = mouthShapes();
    expect(shapes.length, 7);
    expect(shapes.values.map((p) => p.length).toSet().length, 1);
    final bounds = shapes.values.map((p) => toPath(p).getBounds().toString()).toSet();
    expect(bounds.length, 7);
  });

  test('closed rest shape has no opening; open shapes do', () {
    const upperCentre = 4, lowerCentre = 12;
    double centreGap(int code) {
      final points = shapePoints(code);
      expect((points[upperCentre].dx - points[lowerCentre].dx).abs(), lessThan(1e-9));
      return points[lowerCentre].dy - points[upperCentre].dy;
    }

    double height(List<dynamic> points) {
      final ys = points.map((p) => (p.dy as double)).toList();
      return ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b);
    }

    expect(centreGap(restCode), 0);
    expect(centreGap(0) > centreGap(3) && centreGap(3) > centreGap(5) && centreGap(5) > 0, isTrue);
    expect(height(shapePoints(0)), greaterThan(height(shapePoints(6))));
    expect(shapePoints(99).length, shapePoints(restCode).length);
  });

  test('lerp at 0 keeps the start and at 1 reaches the end', () {
    final a = shapePoints(4), b = shapePoints(0);
    expect(lerpPoints(a, b, 0), a);
    expect(lerpPoints(a, b, 1), b);
  });
}
