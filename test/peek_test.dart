import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/peek.dart';

import 'manual_timers.dart';

void main() {
  late ManualTimers timers;
  late PeekController peek;
  late List<bool> changes;

  setUp(() {
    timers = ManualTimers();
    peek = PeekController(enabled: true, timer: timers.create);
    changes = [];
    peek.addListener(() => changes.add(peek.expanded));
  });

  test('starts collapsed and expands the moment the face is shown', () {
    expect(peek.expanded, isFalse);
    peek.attention(true);
    expect(peek.expanded, isTrue);
    expect(timers.pending, isEmpty);
  });

  test('collapses the hold after the face hides', () {
    peek.attention(true);
    peek.attention(false);
    expect(peek.expanded, isTrue);
    expect(timers.pending.single.after, peekHold);
    timers.fireAll();
    expect(peek.expanded, isFalse);
    expect(changes, [true, false]);
  });

  test('the face shown again within the hold cancels the collapse', () {
    peek.attention(true);
    peek.attention(false);
    peek.attention(true);
    expect(timers.pending, isEmpty);
    expect(peek.expanded, isTrue);
    expect(changes, [true]);
  });

  test('repeated attention values change nothing', () {
    peek.attention(false);
    expect(timers.pending, isEmpty);
    peek.attention(true);
    peek.attention(true);
    expect(changes, [true]);
  });

  test('a tap expands for the tap hold, then collapses', () {
    peek.tap();
    expect(peek.expanded, isTrue);
    expect(timers.pending.single.after, tapHold);
    timers.fireAll();
    expect(peek.expanded, isFalse);
  });

  test('attention during a tap hold takes over the timing', () {
    peek.tap();
    peek.attention(true);
    expect(timers.pending, isEmpty);
    peek.attention(false);
    expect(timers.pending.single.after, peekHold);
  });

  test('off means always expanded and no changes announced from attention', () {
    final off = PeekController(enabled: false, timer: timers.create);
    var notified = 0;
    off.addListener(() => notified++);
    expect(off.expanded, isTrue);
    off.attention(true);
    off.attention(false);
    timers.fireAll();
    expect(off.expanded, isTrue);
    expect(notified, 0);
  });

  test('turning peek on collapses unless the face is shown; off expands', () {
    final off = PeekController(enabled: false, timer: timers.create);
    off.setEnabled(true);
    expect(off.expanded, isFalse);
    off.setEnabled(false);
    expect(off.expanded, isTrue);
    off.attention(true);
    off.setEnabled(true);
    expect(off.expanded, isTrue);
  });

  test('a hold keeps the window open through the end of attention and a tap hold; release collapses after the hold', () {
    peek.tap();
    peek.hold(true);
    expect(timers.pending, isEmpty, reason: 'the tap hold is cancelled while held');
    peek.attention(true);
    peek.attention(false);
    timers.fireAll();
    expect(peek.expanded, isTrue);
    peek.hold(false);
    expect(timers.pending.single.after, peekHold);
    timers.fireAll();
    expect(peek.expanded, isFalse);
  });

  test('a one-off expand holds until collapsed; a one-off collapse holds until the face is shown', () {
    peek.setExpanded(true);
    expect(peek.expanded, isTrue);
    expect(timers.pending, isEmpty);
    peek.setExpanded(false);
    expect(peek.expanded, isFalse);
    peek.attention(true);
    peek.setExpanded(false);
    expect(peek.expanded, isFalse);
    peek.attention(false);
    peek.attention(true);
    expect(peek.expanded, isTrue);
  });
}
