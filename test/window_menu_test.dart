import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/window/status_menu.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_menu.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

final _items = buildStatusMenu(const StatusMenuState(mode: WindowMode.kiosk, peek: false, visible: true, face: FaceSpec.visage));

List<String> _titles(List<MenuEntry> items) => [for (final i in items) i.separator ? '-' : i.title];

Widget _app(WindowMenuHost host, {double size = 600, void Function(int)? onStep, VoidCallback? onLeave}) => MaterialApp(
  home: Center(
    child: SizedBox.square(
      dimension: size,
      child: WindowSurface(
        mode: WindowMode.kiosk,
        onLeaveKiosk: onLeave ?? () {},
        onMenu: host.open,
        onDismiss: host.dismiss,
        onStep: onStep,
        child: WindowMenu(
          host: host,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    ),
  ),
);

void main() {
  test('inside the window, the menu has no hide, and no quit in a browser', () {
    final desktop = windowMenuEntries(_items, canQuit: true);
    expect(_titles(desktop).take(2), ['Type a command…', '-']);
    expect(_titles(desktop).last, 'Quit OVOS Visage');
    final web = windowMenuEntries(_items, canQuit: false);
    expect(_titles(web).last, 'Face picker…');
    expect(_titles(web).where((t) => t == 'Hide face' || t == 'Show face'), isEmpty);
  });

  testWidgets('a right-click opens the same menu, and a choice goes to the controller', (tester) async {
    final chosen = <String>[], opens = <bool>[];
    final host = WindowMenuHost(onSelected: chosen.add, canQuit: true, onOpenChanged: opens.add)..show(_items);
    await tester.pumpWidget(_app(host));
    await tester.pump(menuSettle);
    await tester.tapAt(tester.getCenter(find.byType(ColoredBox).last), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsOneWidget);
    expect(find.text('Hide face'), findsNothing);
    await tester.tap(find.text('Full screen'));
    await tester.pumpAndSettle();
    expect(chosen, [kioskItem]);
    expect(opens, [true, false]);
  });

  testWidgets('a request in a window too small for a menu waits until the window grows', (tester) async {
    final host = WindowMenuHost(onSelected: (_) {}, canQuit: true)..show(_items);
    await tester.pumpWidget(_app(host, size: 96));
    await tester.pump(menuSettle);
    host.open(const Offset(40, 40));
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsNothing);
    expect(host.pending, isNotNull);
    await tester.pumpWidget(_app(host, size: 300));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_app(host, size: 600));
    await tester.pump(const Duration(milliseconds: 100));
    expect(host.pending, isNotNull, reason: 'still growing');
    await tester.pump(menuSettle);
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsOneWidget);
    expect(host.pending, isNull);
  });

  testWidgets('the menu key opens it, and the arrow keys step pages', (tester) async {
    final steps = <int>[];
    final host = WindowMenuHost(onSelected: (_) {}, canQuit: true)..show(_items);
    await tester.pumpWidget(_app(host, onStep: steps.add));
    await tester.pump(menuSettle);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(steps, [1, -1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsOneWidget);
  });

  testWidgets('in kiosk, Escape closes an open menu first and leaves kiosk only when nothing is open', (tester) async {
    var leaves = 0;
    final host = WindowMenuHost(onSelected: (_) {}, canQuit: true)..show(_items);
    await tester.pumpWidget(_app(host, onLeave: () => leaves++));
    await tester.pump(menuSettle);
    host.open(const Offset(50, 50));
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsNothing);
    expect(leaves, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(leaves, 1);
  });

  testWidgets('a two-finger tap opens it on a touch screen', (tester) async {
    final host = WindowMenuHost(onSelected: (_) {}, canQuit: true)..show(_items);
    await tester.pumpWidget(_app(host));
    await tester.pump(menuSettle);
    final centre = tester.getCenter(find.byType(ColoredBox).last);
    final one = await tester.startGesture(centre, pointer: 1, kind: PointerDeviceKind.touch);
    final two = await tester.startGesture(centre + const Offset(40, 0), pointer: 2, kind: PointerDeviceKind.touch);
    await one.up();
    await two.up();
    await tester.pumpAndSettle();
    expect(find.text('Full screen'), findsOneWidget);
  });
}
