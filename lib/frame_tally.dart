/// The arithmetic of the frame log (frame_log.dart): budgets, the per-period tally, and the line formats. Pure, so it
/// is tested without the binding.
library;

const frameBudget = Duration(microseconds: 16700);
const frameBudget120 = Duration(microseconds: 8300);

/// The frames of one summary period; each period starts a new one.
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

/// [line] stamped [micros] after [base], in whole ms; both microseconds on the engine's clock (FrameTiming, Timeline.now).
String stampedAt(int micros, int base, String line) => 't=${(micros - base) ~/ 1000} $line';

String _ms(Duration span) => (span.inMicroseconds / 1000).toStringAsFixed(1);
