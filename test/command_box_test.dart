import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/widgets/command_box.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

Widget _host(Widget child) => MaterialApp(home: Material(child: child));

void main() {
  test('the box closes only when the command left', () {
    var leaves = false;
    final opens = <bool>[];
    final box = CommandBoxController(send: (_) => leaves, onOpenChanged: opens.add)..open();
    expect(box.submit('hello'), isFalse);
    expect(box.isOpen, isTrue);
    expect(box.submit('  '), isFalse);
    leaves = true;
    expect(box.submit('hello'), isTrue);
    expect(box.isOpen, isFalse);
    expect(opens, [true, false]);
  });

  testWidgets('typing and Enter sends; Escape closes', (tester) async {
    final sent = <String>[];
    final box = CommandBoxController(
      send: (t) {
        sent.add(t);
        return true;
      },
    )..open();
    await tester.pumpWidget(_host(CommandBox(controller: box)));
    await tester.enterText(find.byType(TextField), 'what time is it');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    expect(sent, ['what time is it']);
    expect(box.isOpen, isFalse);
    box.open();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(box.isOpen, isFalse);
  });

  testWidgets('the box takes the focus from the window surface, which holds it from the start', (tester) async {
    final box = CommandBoxController(send: (_) => true);
    await tester.pumpWidget(
      _host(
        WindowSurface(
          mode: WindowMode.window,
          onLeaveKiosk: () {},
          child: ListenableBuilder(
            listenable: box,
            builder: (_, _) => box.isOpen ? CommandBox(controller: box) : const SizedBox(),
          ),
        ),
      ),
    );
    box.open();
    await tester.pump();
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });
}
