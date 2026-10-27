/// The page swaps of docs/DESIGN.md, Motion language: a page of a new shape squashes to a line and the next expands out
/// of it; a step within a skill's pages slides the old page out and the new one in together (page_moves.dart). The old
/// page stays mounted until its exit ends, and the new page's items enter once it has arrived (EnterCue). Under reduced
/// motion every change is a cut.
///
/// A move transforms a snapshot, never a live page (docs/DESIGN.md, Measured): the leaving page is captured as it starts,
/// and the arriving page mounts at the hold and paints once into its snapshot, which the expand then scales; at the
/// end of the move it paints live again. A page holding a platform view (a web view) cannot be captured and moves live.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../frame_log.dart';
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

/// A page, its cue and its snapshot, kept for the length of its exit.
typedef _Shown = ({Object key, Widget child, _Cue cue, SnapshotController snap});

const _firstCue = (delay: Duration.zero, whole: false);

class _PageSwitchState extends State<PageSwitch> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this)..addStatusListener(_settle);
  _Shown? _leaving;
  PageMove? _move;
  _Cue _cue = _firstCue;

  /// The snapshot of the page on screen; on while it moves, off at rest.
  SnapshotController _snap = SnapshotController();

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
    if (_leaving case final interrupted?) _retire(interrupted.snap);
    _leaving = (key: old.pageKey, child: old.child, cue: _cue, snap: _snap..allowSnapshotting = true);
    _snap = SnapshotController(allowSnapshotting: true);
    _move = move;
    _cue = (delay: arrivalLength(move), whole: move != PageMove.swap);
    _clock
      ..duration = moveLength(move)
      ..forward(from: 0);
    logMove('${_moveName(move)} start');
  }

  void _settle(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_move case final move?) logMove('${_moveName(move)} end');
    setState(_forget);
  }

  /// Disposed after the frame, once the snapshot that listens to [snap] has left the tree.
  static void _retire(SnapshotController snap) => WidgetsBinding.instance.addPostFrameCallback((_) => snap.dispose());

  static String _moveName(PageMove move) => move == PageMove.swap ? 'squash' : 'slide';

  void _cut() {
    _clock.stop();
    _forget();
  }

  /// The move is over: the leaving page goes and the page on screen paints live.
  void _forget() {
    if (_leaving case final leaving?) _retire(leaving.snap);
    _snap.allowSnapshotting = false;
    _leaving = null;
    _move = null;
  }

  @override
  void dispose() {
    _clock.dispose();
    if (_leaving case final leaving?) _retire(leaving.snap);
    _retire(_snap);
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
            if (inPose != null) _posed((key: widget.pageKey, child: widget.child, cue: _cue, snap: _snap), inPose),
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
          child: _Fade(
            opacity: pose.opacity,
            child: SnapshotWidget(
              controller: page.snap,
              mode: SnapshotMode.permissive,
              child: EnterCue(delay: page.cue.delay, whole: page.cue.whole, child: page.child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// An Opacity that paints its child directly when opaque. Flutter's Opacity pushes a layer even at 1.0, and it would sit
/// over every page at rest; dropping the wrapper at rest instead would remount the page when its move ends.
class _Fade extends SingleChildRenderObjectWidget {
  const _Fade({required this.opacity, super.child});

  final double opacity;

  int get _alpha => Color.getAlphaFromOpacity(opacity);

  @override
  _RenderFade createRenderObject(BuildContext context) => _RenderFade(_alpha);

  @override
  void updateRenderObject(BuildContext context, _RenderFade renderObject) => renderObject.alpha = _alpha;
}

class _RenderFade extends RenderProxyBox {
  _RenderFade(this._alpha);

  int _alpha;

  set alpha(int value) {
    if (value == _alpha) return;
    final wasLayered = _layered;
    _alpha = value;
    if (wasLayered != _layered) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  bool get _layered => _alpha < 255;

  @override
  bool get alwaysNeedsCompositing => child != null && _layered;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || _alpha == 0 || !_layered) {
      layer = null;
      if (_alpha != 0) super.paint(context, offset);
      return;
    }
    layer = context.pushOpacity(offset, _alpha, super.paint, oldLayer: layer as OpacityLayer?);
  }
}
