import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

void main() {
  Future<int> dragsOn(WidgetTester tester, WindowMode mode, {bool draggable = true}) async {
    var started = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: WindowSurface(
          mode: mode,
          onLeaveKiosk: () {},
          onDragStart: draggable ? () => started++ : null,
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.drag(find.byType(WindowSurface), const Offset(60, 0));
    await tester.pump();
    return started;
  }

  testWidgets('a drag on a widget starts a window drag', (tester) async {
    expect(await dragsOn(tester, WindowMode.float), 1);
    expect(await dragsOn(tester, WindowMode.desktop), 1);
  });

  testWidgets('an ordinary window, kiosk, and try-on mode do not drag the window', (tester) async {
    expect(await dragsOn(tester, WindowMode.window), 0);
    expect(await dragsOn(tester, WindowMode.kiosk), 0);
    expect(await dragsOn(tester, WindowMode.float, draggable: false), 0);
  });
}
