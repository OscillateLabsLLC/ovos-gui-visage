import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/theme.dart';
import 'package:ovos_gui_visage/window/kiosk_cursor.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

import 'manual_timers.dart';

void main() {
  group('cursor', () {
    late ManualTimers timers;
    late CursorHider cursor;
    late int changes;

    setUp(() {
      timers = ManualTimers();
      cursor = CursorHider(timer: timers.create);
      changes = 0;
      cursor.addListener(() => changes++);
    });

    test('disabled, it never hides and starts no countdown', () {
      cursor.moved();
      expect(timers.pending, isEmpty);
      expect(cursor.hidden, isFalse);
    });

    test('enabled, it hides five seconds after the last movement', () {
      cursor.setEnabled(true);
      expect(timers.pending.single.after, cursorHideAfter);
      expect(cursorHideAfter, const Duration(seconds: 5));
      timers.fireAll();
      expect(cursor.hidden, isTrue);
      expect(changes, 1);
    });

    test('a movement shows it and restarts the countdown', () {
      cursor.setEnabled(true);
      timers.fireAll();
      cursor.moved();
      expect(cursor.hidden, isFalse);
      expect(timers.pending, hasLength(1));
      cursor.moved();
      expect(timers.pending, hasLength(1), reason: 'the earlier countdown is cancelled');
      expect(changes, 2);
    });

    test('disabling shows it and cancels the countdown', () {
      cursor.setEnabled(true);
      timers.fireAll();
      cursor.setEnabled(false);
      expect(cursor.hidden, isFalse);
      expect(timers.pending, isEmpty);
    });
  });

  group('surface', () {
    late ManualTimers timers;
    late int leaves;

    Future<void> pump(WidgetTester tester, WindowMode mode) => tester.pumpWidget(
      MaterialApp(
        home: WindowSurface(mode: mode, onLeaveKiosk: () => leaves++, timer: timers.create, child: const SizedBox.expand()),
      ),
    );

    MouseCursor cursorOf(WidgetTester tester) => tester
        .widget<MouseRegion>(find.descendant(of: find.byType(WindowSurface), matching: find.byType(MouseRegion)).first)
        .cursor;

    Color backgroundOf(WidgetTester tester) =>
        tester.widget<ColoredBox>(find.descendant(of: find.byType(WindowSurface), matching: find.byType(ColoredBox)).first).color;

    setUp(() {
      timers = ManualTimers();
      leaves = 0;
    });

    testWidgets('Escape leaves kiosk', (tester) async {
      await pump(tester, WindowMode.kiosk);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(leaves, 1);
    });

    testWidgets('Escape does nothing in the other modes', (tester) async {
      for (final mode in [WindowMode.window, WindowMode.float, WindowMode.desktop]) {
        await pump(tester, mode);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      expect(leaves, 0);
    });

    testWidgets('the pointer hides after the countdown and comes back when the mouse moves', (tester) async {
      await pump(tester, WindowMode.kiosk);
      expect(cursorOf(tester), MouseCursor.defer);
      timers.fireAll();
      await tester.pump();
      expect(cursorOf(tester), SystemMouseCursors.none);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(10, 10));
      await mouse.moveTo(const Offset(20, 20));
      await tester.pump();
      expect(cursorOf(tester), MouseCursor.defer);
      await mouse.removePointer();
    });

    testWidgets('leaving kiosk shows the pointer and stops hiding it', (tester) async {
      await pump(tester, WindowMode.kiosk);
      timers.fireAll();
      await pump(tester, WindowMode.float);
      expect(cursorOf(tester), MouseCursor.defer);
      expect(timers.pending, isEmpty);
    });

    testWidgets('black behind the frame in kiosk, the page colour in a window, nothing behind a widget', (tester) async {
      final colours = <Color>[];
      for (final mode in WindowMode.values) {
        await pump(tester, mode);
        colours.add(backgroundOf(tester));
      }
      expect(colours, [VisageColors.bg, Colors.transparent, Colors.transparent, Colors.black]);
    });
  });
}
