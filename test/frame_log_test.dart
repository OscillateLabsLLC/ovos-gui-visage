import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/frame_log.dart';

Duration _ms(double ms) => Duration(microseconds: (ms * 1000).round());

void main() {
  test('a frame is late only when build plus raster passes 16.7 ms', () {
    final tally = FrameTally();
    expect(tally.add(_ms(8), _ms(8.7)), isFalse, reason: 'exactly on budget');
    expect(tally.add(_ms(2), _ms(15)), isTrue);
    expect(tally.add(_ms(16.8), Duration.zero), isTrue);
    expect([tally.frames, tally.over], [3, 2]);
  });

  test('the summary keeps the worst build and the worst raster, from different frames', () {
    final tally = FrameTally()
      ..add(_ms(12.3), _ms(4))
      ..add(_ms(3), _ms(21))
      ..add(_ms(1), _ms(1));
    expect(tally.summary(), 'frames: 3 seen, 1 over budget, worst build 12.3 ms, worst raster 21.0 ms');
  });

  test('a reset starts the next period from nothing', () {
    final tally = FrameTally()
      ..add(_ms(30), _ms(30))
      ..reset();
    expect(tally.summary(), 'frames: 0 seen, 0 over budget, worst build 0.0 ms, worst raster 0.0 ms');
  });

  test('the late-frame line', () {
    expect(frameLine(_ms(12.3), _ms(21)), 'frame: build 12.3 ms raster 21.0 ms');
  });

  test('VISAGE_FRAME_LOG turns the log on from the environment only; it is off by default', () {
    expect(AppConfig.from(null, const {}).frameLog, isFalse);
    expect(AppConfig.from(null, const {'VISAGE_FRAME_LOG': '1'}).frameLog, isTrue);
    expect(AppConfig.from(const {'frameLog': true}, const {}).frameLog, isFalse);
  });
}
