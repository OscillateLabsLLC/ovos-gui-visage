import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/image_frame_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
const ctx = PageContext(namespace: hello, page: 'SYSTEM_x', events: {});

void main() {
  group('the fallback degrades (gui-1.md 6.5 and 8.5)', () {
    testWidgets('title and text show as the text page', (tester) async {
      await tester.pumpWidget(host(FallbackPage.page({'title': 'Hi', 'text': 'Hello', 'other': 1}, ctx)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(TextFramePage), findsOneWidget);
      expect([find.text('HI'), find.text('Hello')], everyElement(findsOneWidget));
    });

    testWidgets('a title alone shows as the text', (tester) async {
      await tester.pumpWidget(host(FallbackPage.page({'title': 'Hi'}, ctx)));
      await tester.pump(const Duration(seconds: 1));
      expect([find.byType(TextFramePage), find.text('Hi')], everyElement(findsOneWidget));
    });

    testWidgets('an image shows as the image page, with its caption', (tester) async {
      await tester.pumpWidget(host(FallbackPage.page({'image': png, 'caption': 'A dot', 'text': 'ignored'}, ctx)));
      expect([find.byType(ImageFramePage), find.text('A dot')], everyElement(findsOneWidget));
    });

    testWidgets('anything else is still the dump', (tester) async {
      await tester.pumpWidget(host(FallbackPage.page({'location': 'San Antonio'}, ctx)));
      expect([
        find.text('SYSTEM_x'),
        find.text(hello),
        find.text('location'),
        find.text('San Antonio'),
      ], everyElement(findsOneWidget));
    });

    testWidgets('over GUI-1, an unknown template with text shows the text page', (tester) async {
      final gaps = freshGaps();
      final faults = await collectFaults(() async {
        final state = replayGui1(loadGui1Fixture('unknown_template'), gaps: gaps);
        await tester.pumpWidget(host(pageOf(state, gaps: gaps.templates)));
        await tester.pump(const Duration(seconds: 1));
      });
      expect(faults.single.exceptionAsString(), contains('SYSTEM_hologram'));
      expect([find.byType(FallbackPage), find.byType(TextFramePage), find.text('again')], everyElement(findsOneWidget));
    });
  });
}
