import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/window_bounds_io.dart';

const _widget = Size(240, 400);

List<MappedSizeStep> _readBacks(List<Size> sizes) {
  Size? previous;
  final steps = <MappedSizeStep>[];
  for (final current in sizes) {
    steps.add(mappedSizeStep(wanted: _widget, current: current, previous: previous));
    previous = current;
  }
  return steps;
}

void main() {
  test('a window that reads back the size asked for needs nothing', () {
    expect(_readBacks([_widget]), [MappedSizeStep.done]);
  });

  // Measured on native Wayland (KWin 5.27): 1332x819 before the map, then 188x348 for good.
  test('a window that settles short is resized once it holds still', () {
    expect(_readBacks([const Size(1332, 819), const Size(188, 348), const Size(188, 348)]), [
      MappedSizeStep.wait,
      MappedSizeStep.wait,
      MappedSizeStep.resize,
    ]);
  });

  test('a window still growing to its size is waited for', () {
    expect(_readBacks([const Size(1280, 720), _widget]), [MappedSizeStep.wait, MappedSizeStep.done]);
  });
}
