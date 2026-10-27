/// Moving between the pages of the active skill, as the Qt GUI's SwipeView did: a horizontal swipe on the page, the
/// arrow keys (window_surface.dart) and, in kiosk mode, chevrons in the bottom corners. Only a skill with more than one
/// page gets a swipe, and only a clearly horizontal drag is one, so on a widget every other drag still moves the
/// window. A press anywhere on the page counts as use, which ovos-gui needs to keep the page from timing out.
///
/// A page with inner pages (inner_pager.dart) publishes them through the [InnerPagerScope] put around it here; the
/// swipe and the chevrons then show for it too, [onStep] steps them first (screen_input.dart), and a tap on the left
/// or right third of the page steps them back or ahead. The tap detector sits behind the page, so its controls win.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import 'inner_pager.dart';

/// A swipe this long, or this fast, turns the page.
const swipeDistance = 60.0;
const swipeVelocity = 300.0;

/// A drag counts as a swipe only while it runs at least this many times further across than down.
const swipeSteepness = 2.0;

/// The page [delta] steps from [index] among [count], or null past either end.
int? pageStep(int index, int count, int delta) {
  final next = index + delta;
  return next < 0 || next >= count ? null : next;
}

/// A tap at [x] across a page [width] wide as a step: back in the left third, ahead in the right third, else none.
int tapStep(double x, double width) => x < width / 3 ? -1 : (x > width * 2 / 3 ? 1 : 0);

/// A finished horizontal swipe as a step: leftwards is forwards, as on a phone. Zero when it was too short and slow.
int swipeStep(double distance, double velocity) {
  if (distance.abs() < swipeDistance && velocity.abs() < swipeVelocity) return 0;
  final direction = distance.abs() >= swipeDistance ? distance : velocity;
  return direction < 0 ? 1 : -1;
}

/// A horizontal drag that wins the arena only when it is clearly horizontal; otherwise the window's pan (a widget's
/// drag-to-move) gets the pointer. Flutter's own recognizer accepts at the hit slop on the x axis alone, which a mouse
/// passes after one pixel of any diagonal drag.
class HorizontalSwipeRecognizer extends HorizontalDragGestureRecognizer {
  HorizontalSwipeRecognizer({super.debugOwner});

  Offset _start = Offset.zero;
  Offset _moved = Offset.zero;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _start = event.position;
    _moved = Offset.zero;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) _moved = event.position - _start;
    super.handleEvent(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(PointerDeviceKind pointerDeviceKind, double? deviceTouchSlop) =>
      super.hasSufficientGlobalDistanceToAccept(pointerDeviceKind, deviceTouchSlop) &&
      _moved.dx.abs() > swipeSteepness * _moved.dy.abs();
}

class PagePager extends StatefulWidget {
  const PagePager({
    super.key,
    required this.index,
    required this.count,
    required this.onStep,
    required this.onInteract,
    required this.chevrons,
    required this.child,
    this.inner,
  });

  final int index;
  final int count;
  final void Function(int delta) onStep;
  final VoidCallback onInteract;
  final bool chevrons;
  final Widget child;

  /// Where the page on screen publishes its inner pages; null where nothing pages inside a page.
  final InnerPagerSlot? inner;

  @override
  State<PagePager> createState() => _PagePagerState();
}

class _PagePagerState extends State<PagePager> {
  double _distance = 0;

  InnerPager? get _innerPages => widget.inner?.current;

  bool get _paged => widget.count > 1 || _innerPages != null;

  bool _canStep(int delta) => pageStep(widget.index, widget.count, delta) != null || (widget.inner?.canStep(delta) ?? false);

  @override
  Widget build(BuildContext context) {
    final inner = widget.inner;
    if (inner == null) return _pager(widget.child);
    return ListenableBuilder(
      listenable: inner,
      builder: (context, page) => _pager(page!),
      child: InnerPagerScope(slot: inner, child: widget.child),
    );
  }

  Widget _pager(Widget page) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => widget.onInteract(),
    child: Stack(
      fit: StackFit.expand,
      children: [
        RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {if (_paged) ..._swipe(), if (_innerPages != null) ..._tap()},
          child: page,
        ),
        if (widget.chevrons && _paged) ..._chevrons(),
      ],
    ),
  );

  Map<Type, GestureRecognizerFactory> _tap() => {
    TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (tap) => tap.onTapUp = (details) {
        final step = tapStep(details.localPosition.dx, context.size?.width ?? 0);
        if (step != 0) widget.inner?.step(step);
      },
    ),
  };

  Map<Type, GestureRecognizerFactory> _swipe() => {
    HorizontalSwipeRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalSwipeRecognizer>(
      () => HorizontalSwipeRecognizer(debugOwner: this),
      (swipe) => swipe
        ..onStart = ((_) => _distance = 0)
        ..onUpdate = ((d) => _distance += d.delta.dx)
        ..onEnd = _end,
    ),
  };

  void _end(DragEndDetails details) {
    final step = swipeStep(_distance, details.velocity.pixelsPerSecond.dx);
    if (step != 0) widget.onStep(step);
  }

  List<Widget> _chevrons() => [
    if (_canStep(-1)) _chevron(Alignment.bottomLeft, Icons.chevron_left, -1),
    if (_canStep(1)) _chevron(Alignment.bottomRight, Icons.chevron_right, 1),
  ];

  Widget _chevron(Alignment where, IconData icon, int delta) => Align(
    alignment: where,
    child: IconButton(
      tooltip: delta < 0 ? 'Previous page' : 'Next page',
      iconSize: 44,
      color: VisageColors.muted,
      onPressed: () => widget.onStep(delta),
      icon: Icon(icon),
    ),
  );
}
