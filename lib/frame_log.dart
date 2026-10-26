/// Opt-in frame timing (`VISAGE_FRAME_LOG=1`, app_config.dart): each frame over 16.7 ms (build plus raster) stamped at
/// its vsync, the moves' starts and ends (logMove) and a summary every 10 s stamped with Timeline.now, all in ms since
/// the log started on the engine's monotonic clock. The first batch of timings logs how far its vsync lies from now: a
/// gap of seconds would mean the two clocks differ and the stamps cannot be compared.
library;

import 'dart:async';
import 'dart:developer' show Timeline;
import 'dart:ui' show FrameTiming, FramePhase;

import 'package:flutter/scheduler.dart';

import 'frame_tally.dart';

export 'frame_tally.dart';

const summaryEvery = Duration(seconds: 10);

var _base = 0;
void Function(String line)? _sink;

void _stamp(int micros, String line) => _sink?.call(stampedAt(micros, _base, line));

/// A move's start or end (`squash start`, `birth end`); nothing unless the log is on.
void logMove(String event) => _stamp(Timeline.now, 'move: $event');

/// Logs every late frame through [log], and the tally every [summaryEvery].
void startFrameLog(void Function(String line) log) {
  var tally = FrameTally();
  var clockChecked = false;
  _sink = log;
  _base = Timeline.now;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    if (!clockChecked) {
      clockChecked = true;
      _stamp(Timeline.now, 'frame log: last vsync ${(Timeline.now - _vsync(timings.last)) ~/ 1000} ms before now');
    }
    for (final t in timings) {
      if (tally.add(t.buildDuration, t.rasterDuration)) _stamp(_vsync(t), frameLine(t.buildDuration, t.rasterDuration));
    }
  });
  Timer.periodic(summaryEvery, (_) {
    _stamp(Timeline.now, tally.summary());
    tally = FrameTally();
  });
}

int _vsync(FrameTiming timing) => timing.timestampInMicroseconds(FramePhase.vsyncStart);
