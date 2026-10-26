/// The two page swaps of docs/DESIGN.md, Motion language, as poses over time: which move a change of page makes, and
/// where the leaving and the arriving page stand at each moment of it. Pure, so the timeline is tested frame by frame;
/// page_switch.dart draws it.
library;

import 'package:flutter/animation.dart';

/// A page of a new shape squashes to a line and the next expands out of it; a step within a skill's pages slides.
enum PageMove { swap, forward, back }

/// The exit anticipates with a small grow, then squashes fast to a line; the line holds a beat; the next page expands.
const swapAnticipate = Duration(milliseconds: 60);
const swapSquash = Duration(milliseconds: 160);
const swapHold = Duration(milliseconds: 100);
const swapExpand = Duration(milliseconds: 200);
const slideLength = Duration(milliseconds: 200);

/// The grow of the anticipation, the height of the line, and the opacity the line holds at.
const anticipateScale = 1.04;
const lineScale = 0.02;
const _lineOpacity = 0.6;

/// The entry curve of the motion language.
const arriveCurve = Curves.easeOutBack;

final swapLength = swapAnticipate + swapSquash + swapHold + swapExpand;
final _squashEnds = swapAnticipate + swapSquash;
final _expandStarts = _squashEnds + swapHold;

/// Where a page stands: its scale, its sideways shift in page widths, and its opacity.
typedef PagePose = ({double scaleX, double scaleY, double dx, double opacity});

const restingPose = (scaleX: 1.0, scaleY: 1.0, dx: 0.0, opacity: 1.0);

/// The move from the page at [fromIndex] of [fromGroup] to the one at [toIndex] of [toGroup]: a slide only for a step
/// between pages of the same group, in the step's direction.
PageMove pageMove({Object? fromGroup, int fromIndex = 0, Object? toGroup, int toIndex = 0}) {
  if (fromGroup == null || fromGroup != toGroup || fromIndex == toIndex) return PageMove.swap;
  return toIndex > fromIndex ? PageMove.forward : PageMove.back;
}

Duration moveLength(PageMove move) => move == PageMove.swap ? swapLength : slideLength;

/// How long after it first shows the arriving page is still arriving; its items wait that long.
Duration arrivalLength(PageMove move) => move == PageMove.swap ? swapExpand : slideLength;

double _progress(Duration elapsed, Duration from, Duration length) =>
    ((elapsed - from).inMicroseconds / length.inMicroseconds).clamp(0.0, 1.0);

/// The leaving page [elapsed] into [move]; null once it has gone.
PagePose? leavingPose(PageMove move, Duration elapsed) {
  if (move != PageMove.swap) {
    if (elapsed >= slideLength) return null;
    final p = Curves.easeInOut.transform(_progress(elapsed, Duration.zero, slideLength));
    return (scaleX: 1, scaleY: 1, dx: -_direction(move) * p, opacity: 1);
  }
  if (elapsed < swapAnticipate) {
    final grow = 1 + (anticipateScale - 1) * _progress(elapsed, Duration.zero, swapAnticipate);
    return (scaleX: grow, scaleY: grow, dx: 0, opacity: 1);
  }
  if (elapsed < _squashEnds) {
    final p = Curves.easeIn.transform(_progress(elapsed, swapAnticipate, swapSquash));
    return (
      scaleX: anticipateScale,
      scaleY: anticipateScale + (lineScale - anticipateScale) * p,
      dx: 0,
      opacity: 1 - (1 - _lineOpacity) * p,
    );
  }
  if (elapsed < _expandStarts) {
    return (
      scaleX: anticipateScale,
      scaleY: lineScale,
      dx: 0,
      opacity: _lineOpacity * (1 - _progress(elapsed, _squashEnds, swapHold)),
    );
  }
  return null;
}

/// The arriving page [elapsed] into [move]; null before it shows.
PagePose? arrivingPose(PageMove move, Duration elapsed) {
  if (move != PageMove.swap) {
    final p = Curves.easeInOut.transform(_progress(elapsed, Duration.zero, slideLength));
    return (scaleX: 1, scaleY: 1, dx: _direction(move) * (1 - p), opacity: 1);
  }
  if (elapsed < _expandStarts) return null;
  final p = arriveCurve.transform(_progress(elapsed, _expandStarts, swapExpand));
  return (scaleX: 1, scaleY: lineScale + (1 - lineScale) * p, dx: 0, opacity: 1);
}

double _direction(PageMove move) => move == PageMove.forward ? 1 : -1;
