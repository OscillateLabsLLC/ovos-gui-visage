/// The page swaps of docs/DESIGN.md, Motion language: a page of a new shape squashes to a line and the next expands out
/// of it; a step within a skill's pages slides the old page out and the new one in together (page_moves.dart). The old
/// page stays mounted until its exit ends, and the new page's items enter once it has arrived (EnterCue). Under reduced
/// motion every change is a cut.
library;

import 'package:flutter/widgets.dart';

import 'circle.dart';
import 'page_moves.dart';

export 'page_moves.dart' show PageMove;

/// Hosts one page at a time; a new [pageKey] moves to the new [child]. [group] and [index] place the page among its
/// skill's pages, so a step between them slides instead of swapping.
class PageSwitch extends StatefulWidget {
  const PageSwitch({super.key, required this.pageKey, required this.child, this.group, this.index = 0});

  final Object pageKey;
  final Object? group;
  final int index;
  final Widget child;

  @override
  State<PageSwitch> createState() => _PageSwitchState();
}

/// How a page's items enter (EnterCue).
typedef _Cue = ({Duration delay, bool whole});

/// A page and its cue, kept for the length of its exit.
typedef _Shown = ({Object key, Widget child, _Cue cue});

const _firstCue = (delay: Duration.zero, whole: false);

class _PageSwitchState extends State<PageSwitch> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this)..addStatusListener(_settle);
  _Shown? _leaving;
  PageMove? _move;
  _Cue _cue = _firstCue;

  Duration get _elapsed => (_clock.duration ?? Duration.zero) * _clock.value;

  /// The arriving page has not shown yet: the line is still squashing or holding.
  bool get _arrivalPending => _move != null && arrivingPose(_move!, _elapsed) == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (motionReduced(context)) _cut();
  }

  @override
  void didUpdateWidget(PageSwitch old) {
    super.didUpdateWidget(old);
    if (old.pageKey == widget.pageKey) return;
    if (motionReduced(context)) return _cut();
    if (_arrivalPending) return;
    final move = pageMove(fromGroup: old.group, fromIndex: old.index, toGroup: widget.group, toIndex: widget.index);
    _leaving = (key: old.pageKey, child: old.child, cue: _cue);
    _move = move;
    _cue = (delay: arrivalLength(move), whole: move != PageMove.swap);
    _clock
      ..duration = moveLength(move)
      ..forward(from: 0);
  }

  void _settle(AnimationStatus status) {
    if (status == AnimationStatus.completed) setState(_forget);
  }

  void _cut() {
    _clock.stop();
    _forget();
  }

  void _forget() {
    _leaving = null;
    _move = null;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _clock,
      builder: (context, _) {
        final (move, leaving) = (_move, _leaving);
        final outPose = move == null || leaving == null ? null : leavingPose(move, _elapsed);
        final inPose = move == null ? restingPose : arrivingPose(move, _elapsed);
        return Stack(
          fit: StackFit.expand,
          children: [
            if (leaving != null && outPose != null) _posed(leaving, outPose, leaving: true),
            if (inPose != null) _posed((key: widget.pageKey, child: widget.child, cue: _cue), inPose),
          ],
        );
      },
    );
  }

  /// The same wrappers for a leaving and an arriving page, so a page keeps its state when it turns from one to the other.
  Widget _posed(_Shown page, PagePose pose, {bool leaving = false}) => KeyedSubtree(
    key: ValueKey(page.key),
    child: IgnorePointer(
      ignoring: leaving,
      child: FractionalTranslation(
        translation: Offset(pose.dx, 0),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(pose.scaleX, pose.scaleY, 1),
          child: Opacity(
            opacity: pose.opacity,
            child: EnterCue(delay: page.cue.delay, whole: page.cue.whole, child: page.child),
          ),
        ),
      ),
    ),
  );
}
