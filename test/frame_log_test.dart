import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/frame_log.dart';

Duration _ms(double ms) => Duration(microseconds: (ms * 1000).round());

void main() {
  test('a frame is late only when build plus raster passes 16.7 ms; the 120 Hz count passes 8.3 ms', () {
    final tally = FrameTally();
    expect(tally.add(_ms(8), _ms(8.7)), isFalse, reason: 'exactly on the 60 Hz budget');
    expect(tally.add(_ms(2), _ms(15)), isTrue);
    expect(tally.add(_ms(16.8), Duration.zero), isTrue);
    expect(tally.add(_ms(4), _ms(4.3)), isFalse, reason: 'exactly on the 120 Hz budget');
    expect(tally.add(_ms(1), _ms(8)), isFalse);
    expect([tally.frames, tally.over, tally.over120], [5, 2, 4]);
  });

  test('the summary keeps the worst build and the worst raster, from different frames', () {
    final tally = FrameTally()
      ..add(_ms(12.3), _ms(4))
      ..add(_ms(3), _ms(21))
      ..add(_ms(1), _ms(1));
    expect(tally.summary(), 'frames: 3 seen, 1 over 16.7 ms, 2 over 8.3 ms, worst build 12.3 ms, worst raster 21.0 ms');
  });

  test('a new period starts from nothing', () {
    expect(FrameTally().summary(), 'frames: 0 seen, 0 over 16.7 ms, 0 over 8.3 ms, worst build 0.0 ms, worst raster 0.0 ms');
  });

  test('the late-frame line, stamped in whole ms after the base on the engine clock', () {
    expect(frameLine(_ms(12.3), _ms(21)), 'frame: build 12.3 ms raster 21.0 ms');
    const base = 9000000000;
    expect(stampedAt(base + 48213900, base, 'move: squash start'), 't=48213 move: squash start');
    expect(stampedAt(base + 999, base, 'frame: x'), 't=0 frame: x', reason: 'whole ms, rounded down');
  });

  test('a move marker is silent while the log is off', () {
    expect(() => logMove('squash start'), returnsNormally);
  });

  test('VISAGE_FRAME_LOG turns the log on from the environment only; it is off by default', () {
    expect(AppConfig.from(null, const {}).frameLog, isFalse);
    expect(AppConfig.from(null, const {'VISAGE_FRAME_LOG': '1'}).frameLog, isTrue);
    expect(AppConfig.from(const {'frameLog': true}, const {}).frameLog, isFalse);
  });
}
