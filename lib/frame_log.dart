/// Opt-in frame timing (`VISAGE_FRAME_LOG=1`, app_config.dart): each frame over 16.7 ms (build plus raster), the moves'
/// starts and ends (logMove) and a summary every 10 s, each line stamped with the milliseconds since the log started.
library;

import 'dart:async';

import 'package:flutter/scheduler.dart';

const frameBudget = Duration(microseconds: 16700);
const frameBudget120 = Duration(microseconds: 8300);
const summaryEvery = Duration(seconds: 10);

/// The frames of one summary period; each period starts a new one. Pure, so the arithmetic is tested without the binding.
class FrameTally {
  int frames = 0, over = 0, over120 = 0;
  Duration worstBuild = Duration.zero, worstRaster = Duration.zero;

  /// Counts one frame; true when its build plus raster time went over [frameBudget].
  bool add(Duration build, Duration raster) {
    frames++;
    if (build > worstBuild) worstBuild = build;
    if (raster > worstRaster) worstRaster = raster;
    if (build + raster > frameBudget120) over120++;
    final late = build + raster > frameBudget;
    if (late) over++;
    return late;
  }

  String summary() =>
      'frames: $frames seen, $over over 16.7 ms, $over120 over 8.3 ms, '
      'worst build ${_ms(worstBuild)} ms, worst raster ${_ms(worstRaster)} ms';
}

String frameLine(Duration build, Duration raster) => 'frame: build ${_ms(build)} ms raster ${_ms(raster)} ms';
String stamped(Duration elapsed, String line) => 't=${elapsed.inMilliseconds} $line';
String _ms(Duration span) => (span.inMicroseconds / 1000).toStringAsFixed(1);
final _since = Stopwatch();
void Function(String line)? _sink;
void _log(String line) => _sink?.call(stamped(_since.elapsed, line));

/// A move's start or end (`squash start`, `birth end`); nothing unless the log is on.
void logMove(String event) => _log('move: $event');

/// Logs every late frame through [log], and the tally every [summaryEvery].
void startFrameLog(void Function(String line) log) {
  var tally = FrameTally();
  _sink = log;
  _since.start();
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final t in timings) {
      if (tally.add(t.buildDuration, t.rasterDuration)) _log(frameLine(t.buildDuration, t.rasterDuration));
    }
  });
  Timer.periodic(summaryEvery, (_) {
    _log(tally.summary());
    tally = FrameTally();
  });
}
