import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/input_box_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_surface.dart';

Widget _host(Widget child) => MaterialApp(home: Material(child: child));

void main() {
  testWidgets('the input box answers the skill as SYSTEM_InputBox.qml did', (tester) async {
    final sent = <Json>[];
    final ctx = PageContext(
      namespace: 'some.skill',
      page: 'SYSTEM_InputBox',
      events: const {},
      send: (m) {
        sent.add(m);
        return true;
      },
    );
    final data = {'title': 'Name?', 'placeholder': 'say a name', 'confirm_text': 'OK', 'exit_text': 'Cancel'};
    await tester.pumpWidget(_host(InputBoxPage.page(data, ctx)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Name?'), findsOneWidget);
    expect(find.text('say a name'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ada');
    await tester.tap(find.text('OK'));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(find.text('Cancel'));
    expect([for (final m in sent) m['event_name']], ['input.box.response', 'input.box.response', 'input.box.close']);
    expect(sent.first, {
      'type': 'mycroft.events.triggered',
      'namespace': 'some.skill',
      'event_name': 'input.box.response',
      'parameters': {'text': 'Ada'},
    });
    expect(sent.last['parameters'], isEmpty);
  });

  testWidgets('the field takes the focus from the window surface, so typing needs no click', (tester) async {
    const ctx = PageContext(namespace: 'some.skill', page: 'SYSTEM_InputBox', events: {});
    await tester.pumpWidget(
      _host(WindowSurface(mode: WindowMode.window, onLeaveKiosk: () {}, child: InputBoxPage.page(const {'title': 'Name?'}, ctx))),
    );
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue);
  });
}
