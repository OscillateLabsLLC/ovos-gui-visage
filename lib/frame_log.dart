/// Opt-in frame timing (`VISAGE_FRAME_LOG=1`, app_config.dart), so stutter is measured: one line per frame whose build
/// plus raster time is over budget, and a summary every 10 s.
library;

import 'dart:async';

import 'package:flutter/scheduler.dart';

/// One frame at 60 Hz.
const frameBudget = Duration(microseconds: 16700);
const summaryEvery = Duration(seconds: 10);

/// The frames of one summary period. Pure, so the arithmetic is tested without the binding.
class FrameTally {
  int frames = 0;
  int over = 0;
  Duration worstBuild = Duration.zero;
  Duration worstRaster = Duration.zero;

  /// Counts one frame; true when its build plus raster time went over [frameBudget].
  bool add(Duration build, Duration raster) {
    frames++;
    if (build > worstBuild) worstBuild = build;
    if (raster > worstRaster) worstRaster = raster;
    final late = build + raster > frameBudget;
    if (late) over++;
    return late;
  }

  String summary() =>
      'frames: $frames seen, $over over budget, worst build ${_ms(worstBuild)} ms, worst raster ${_ms(worstRaster)} ms';

  void reset() {
    frames = over = 0;
    worstBuild = worstRaster = Duration.zero;
  }
}

String frameLine(Duration build, Duration raster) => 'frame: build ${_ms(build)} ms raster ${_ms(raster)} ms';

String _ms(Duration span) => (span.inMicroseconds / 1000).toStringAsFixed(1);

/// Logs every late frame through [log], and the tally every [summaryEvery].
void startFrameLog(void Function(String line) log) {
  final tally = FrameTally();
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      if (tally.add(timing.buildDuration, timing.rasterDuration)) log(frameLine(timing.buildDuration, timing.rasterDuration));
    }
  });
  Timer.periodic(summaryEvery, (_) {
    log(tally.summary());
    tally.reset();
  });
}
