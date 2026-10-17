import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/lottie/segment.dart';

void main() {
  test('a one-shot stops at the last live layer frame', () {
    final data = {
      'ip': 0,
      'op': 45,
      'layers': [
        {'op': 40},
        {'op': 40},
      ],
    };
    expect(liveSegment(data), (start: 0.0, end: 40.0));
  });

  test('layers without op use the composition end', () {
    expect(liveSegment({'ip': 0, 'op': 70, 'layers': [{}]}), (start: 0.0, end: 70.0));
    expect(liveSegment({'ip': 0, 'op': 70}), (start: 0.0, end: 0.0));
  });
}
