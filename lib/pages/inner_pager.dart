/// Pages inside one page, such as a long text split to fit (text_frame_page.dart). The page publishes an [InnerPager]
/// in the [InnerPagerSlot] the shell puts around it ([InnerPagerScope], page_pager.dart), and the shell's gestures step
/// it before the skill's own pages (docs/SCOPE.md, Input). A person's steps stop at either end; the page's own turning
/// may loop, and it waits [autoHoldAfterStep] after a person's step.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

const _shortestHold = Duration(seconds: 20);

/// How long a page's own turning waits after a person steps to a page shown for [pageTime]: three of those, at least
/// 20 s.
Duration autoHoldAfterStep(Duration pageTime) => pageTime * 3 > _shortestHold ? pageTime * 3 : _shortestHold;

class InnerPager extends ChangeNotifier {
  InnerPager({required this.count, required this.pageTime});

  final int count;

  /// How long the inner page at an index shows when it turns by itself.
  final Duration Function(int index) pageTime;

  int _index = 0;
  Duration? _hold;

  int get index => _index;

  bool canStep(int delta) => delta != 0 && _index + delta >= 0 && _index + delta < count;

  /// A person's step: shows the page [delta] away and holds the page's own turning; false at either end.
  bool step(int delta) {
    if (!canStep(delta)) return false;
    _index += delta;
    holdAuto(autoHoldAfterStep(pageTime(_index)));
    return true;
  }

  /// Asks the page to wait [hold] before it turns by itself again; the page takes it with [takeHold].
  void holdAuto(Duration hold) {
    _hold = hold;
    notifyListeners();
  }

  /// The hold not yet honoured, once.
  Duration? takeHold() {
    final hold = _hold;
    _hold = null;
    return hold;
  }

  /// The page turned by itself.
  void turnTo(int index) {
    if (index == _index) return;
    _index = index;
    notifyListeners();
  }
}

/// The inner pager of the page on screen, if it has one. A page publishes and withdraws while it builds or is disposed,
/// when the shell cannot rebuild, so listeners hear of the change in a microtask.
class InnerPagerSlot extends ChangeNotifier {
  InnerPager? _current;
  bool _pending = false;
  bool _disposed = false;

  InnerPager? get current => _current;

  bool canStep(int delta) => _current?.canStep(delta) ?? false;

  bool step(int delta) => _current?.step(delta) ?? false;

  void publish(InnerPager pager) {
    _current?.removeListener(_changed);
    _current = pager..addListener(_changed);
    _changed();
  }

  void withdraw(InnerPager pager) {
    if (_current != pager) return;
    pager.removeListener(_changed);
    _current = null;
    _changed();
  }

  void _changed() {
    if (_pending) return;
    _pending = true;
    scheduleMicrotask(() {
      _pending = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Puts [slot] where the page on screen can publish its inner pager.
class InnerPagerScope extends InheritedWidget {
  const InnerPagerScope({super.key, required this.slot, required super.child});

  final InnerPagerSlot slot;

  static InnerPagerSlot? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<InnerPagerScope>()?.slot;

  @override
  bool updateShouldNotify(InnerPagerScope oldWidget) => oldWidget.slot != slot;
}
