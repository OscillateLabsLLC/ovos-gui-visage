import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/two_finger_tap.dart';

void main() {
  group('two-finger tap', () {
    late List<Offset> taps;
    late TwoFingerTap detector;
    const t0 = Duration.zero;
    const quick = Duration(milliseconds: 150);

    setUp(() {
      taps = [];
      detector = TwoFingerTap(onTap: taps.add);
    });

    test('two quick still fingers tap at their midpoint', () {
      detector.down(1, const Offset(10, 10), t0);
      detector.down(2, const Offset(30, 50), t0);
      detector.up(1, quick);
      detector.up(2, quick);
      expect(taps, [const Offset(20, 30)]);
    });

    test('one finger, three fingers, a slow hold or a moving finger are not taps', () {
      detector
        ..down(1, Offset.zero, t0)
        ..up(1, quick);
      detector
        ..down(1, Offset.zero, t0)
        ..down(2, Offset.zero, t0)
        ..down(3, Offset.zero, t0)
        ..up(1, quick)
        ..up(2, quick)
        ..up(3, quick);
      detector
        ..down(1, Offset.zero, t0)
        ..down(2, Offset.zero, t0)
        ..up(1, const Duration(seconds: 1))
        ..up(2, const Duration(seconds: 1));
      detector
        ..down(1, Offset.zero, t0)
        ..down(2, Offset.zero, t0)
        ..move(2, const Offset(60, 0))
        ..up(1, quick)
        ..up(2, quick);
      expect(taps, isEmpty);
    });
  });
}
