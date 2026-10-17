import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/blank_page.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

void main() {
  test('no target resolves to the blank page', () {
    expect(resolve(null)({}, stubCtx), isA<BlankPage>());
  });

  test('an unknown page resolves to the fallback', () {
    final widget = resolve(const Target('some.skill', 'Mystery', 0))({'a': 1}, stubCtx);
    expect(widget, isA<FallbackPage>());
  });

  testWidgets('PageHost shows the fallback with the namespace, page and data', (tester) async {
    final state = GuiState();
    state.apply({'type': 'mycroft.session.list.insert', 'namespace': activeSkills, 'position': 0, 'data': [{'skill_id': 'x.skill'}]});
    state.apply({'type': 'mycroft.session.set', 'namespace': 'x.skill', 'data': {'greeting': 'hi', 'n': 2}});
    state.apply({'type': 'mycroft.gui.list.insert', 'namespace': 'x.skill', 'position': 0, 'data': [{'page': 'Odd'}]});
    await tester.pumpWidget(MaterialApp(home: Material(child: PageHost(state: state))));
    expect(find.text('Odd'), findsOneWidget);
    expect(find.text('x.skill'), findsOneWidget);
    expect(find.text('hi'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('the blank page shows a clock', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Material(child: BlankPage())));
    expect(find.textContaining(':'), findsOneWidget);
  });

  test('blank page clock and date lines', () {
    final at = DateTime(2026, 10, 17, 9, 5);
    expect(clockLine(at), '09:05');
    expect(dateLine(at), 'Saturday, 17 October');
  });
}

const stubCtx = PageContext(namespace: 'ns', page: 'p', events: {});
