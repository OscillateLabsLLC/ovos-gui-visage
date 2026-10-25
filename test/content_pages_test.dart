import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/content_models.dart';
import 'package:ovos_gui_visage/pages/error_page.dart';
import 'package:ovos_gui_visage/pages/grid_page.dart';
import 'package:ovos_gui_visage/pages/list_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/shell_overlays.dart' show attentionStrip;
import 'package:ovos_gui_visage/pages/table_page.dart';
import 'package:ovos_gui_visage/pages/template_keys.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/widgets/circle.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const png =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
const ctx = PageContext(namespace: hello, page: 'SYSTEM_x', events: {});

/// Replays the template's hand-written fixture through the GUI-1 apply path and pumps the page it shows.
Future<GuiState> pumpFixture(WidgetTester tester, String template) async {
  final state = replayGui1(loadGui1Fixture(template.toLowerCase()));
  expect(state.current(), Target(hello, template, 0));
  await tester.pumpWidget(host(pageOf(state)));
  await tester.pump(const Duration(seconds: 1));
  return state;
}

const templatesA = [errorTemplate, listTemplate, gridTemplate, tableTemplate];

/// The page box inside the 480 x 800 frame: 24 px sides, 32 px top, and 32 px below, or the compact face strip while
/// the face is shown. The corner widget scales this same frame down, so these are the layouts it shows too.
const pageWidth = 480.0 - 2 * 24;
const fullHeight = 800.0 - 2 * 32;
const compactHeight = 800.0 - 32 - attentionStrip;

/// Pumps the page the template's fixture shows, in a [height] page box, with animations off when [still].
Future<void> pumpFrame(WidgetTester tester, String template, {double height = fullHeight, bool still = false}) async {
  final page = pageOf(replayGui1(loadGui1Fixture(template.toLowerCase())));
  final media = MediaQueryData(size: const Size(480, 800), disableAnimations: still);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: media,
        child: Material(
          child: Center(
            child: SizedBox(width: pageWidth, height: height, child: page),
          ),
        ),
      ),
    ),
  );
}

/// Pumps [page] built from [data] and returns the report lines it made.
Future<List<String>> pumpReported(WidgetTester tester, PageBuilder page, Json data) async {
  final faults = await collectFaults(() async {
    await tester.pumpWidget(host(page(data, ctx)));
    await tester.pump(const Duration(seconds: 1));
  });
  return [for (final f in faults) f.exceptionAsString()];
}

void main() {
  setUp(forgetReportedKeys);

  group('from GUI-1 fixtures', () {
    testWidgets('SYSTEM_error shows the mark, the label and the detail', (tester) async {
      await pumpFixture(tester, errorTemplate);
      expect(find.byType(ErrorPage), findsOneWidget);
      for (final text in [errorMark, 'Could not reach the weather service', 'The request timed out after 10 seconds.']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });

    testWidgets('SYSTEM_list shows the title and every item, a thumbnail only where the item has one', (tester) async {
      await pumpFixture(tester, listTemplate);
      expect(find.byType(ListView), findsOneWidget);
      for (final text in ['Shopping list', 'Eggs', 'A dozen', 'Flour', 'Plain, 1 kg', 'Milk']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byType(ListRow), findsNWidgets(3));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('SYSTEM_grid shows every tile with its image in two columns at 432 px', (tester) async {
      await pumpFixture(tester, gridTemplate);
      for (final text in ['Albums', 'Kind of Blue', 'Blue Train', 'Mingus Ah Um']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect([find.byType(GridItemView), find.byType(Image)], everyElement(findsNWidgets(4)));
      final tiles = [for (final e in find.byType(GridItemView).evaluate()) tester.getTopLeft(find.byWidget(e.widget))];
      expect(tiles.map((o) => o.dy).toSet(), hasLength(2), reason: 'four tiles in two rows of two');
    });

    testWidgets('SYSTEM_table shows the header and the rows, a number cell as text', (tester) async {
      await pumpFixture(tester, tableTemplate);
      for (final text in ['Departures', 'TRAIN', 'PLATFORM', 'TIME', 'Express', '08:15', 'Local', '4', 'Night', '23:50']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    });
  });

  group('degraded data still renders, reported', () {
    testWidgets('SYSTEM_error without a label shows the generic label and the detail', (tester) async {
      final faults = await pumpReported(tester, ErrorPage.page, {'detail': 'Wi-Fi is off'});
      expect(faults.single, contains('label is required'));
      expect([find.text(errorWithoutLabel), find.text('Wi-Fi is off')], everyElement(findsOneWidget));
    });

    testWidgets('SYSTEM_list: a bare path drops the thumbnail and keeps the item', (tester) async {
      final faults = await pumpReported(tester, ListPage.page, {
        'items': [
          {'title': 'Eggs', 'image': '/Users/me/eggs.png'},
        ],
      });
      expect(faults.single, contains('/Users/me/eggs.png'));
      expect(find.text('Eggs'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('SYSTEM_list without items shows the empty hint, no fault', (tester) async {
      expect(await pumpReported(tester, ListPage.page, {'title': 'Groceries'}), isEmpty);
      expect([find.text('Groceries'), find.text(emptyList)], everyElement(findsOneWidget));
    });

    testWidgets('SYSTEM_grid: a tile without an image shows its title on the tile', (tester) async {
      final faults = await pumpReported(tester, GridPage.page, {
        'items': [
          {'title': 'Blue Train'},
        ],
      });
      expect(faults.single, contains('image is required'));
      expect(find.descendant(of: find.byType(Circle), matching: find.text('Blue Train')), findsOneWidget);
    });

    testWidgets('SYSTEM_table: a short row is padded, a long one truncated', (tester) async {
      final faults = await pumpReported(tester, TablePage.page, {
        'columns': ['A', 'B'],
        'rows': [
          ['x'],
          ['y', 'z', 'cut'],
        ],
      });
      expect(faults, [contains('rows[0] has 1 cells'), contains('rows[1] has 3 cells')]);
      expect([find.text('x'), find.text('y'), find.text('z')], everyElement(findsOneWidget));
      expect(find.text('cut'), findsNothing);
    });

    testWidgets('SYSTEM_table without rows shows the header and the empty hint', (tester) async {
      final faults = await pumpReported(tester, TablePage.page, {
        'columns': ['A'],
      });
      expect(faults.single, contains('rows is required'));
      expect([find.text('A'), find.text(emptyTable)], everyElement(findsOneWidget));
    });
  });

  group('reduced motion draws the still frame', () {
    for (final template in templatesA) {
      testWidgets(template, (tester) async {
        await pumpFrame(tester, template, still: true);
        expect(tester.hasRunningAnimations, isFalse, reason: 'nothing moves on the first frame');
        expect([
          find.byType(StaggerEnter),
          find.byType(RiseIn),
          find.byType(Glow),
          find.byType(Opacity),
        ], everyElement(findsNothing));
      });
    }

    testWidgets('SYSTEM_error keeps its red halo standing still', (tester) async {
      await pumpFrame(tester, errorTemplate, still: true);
      expect(find.byType(ErrorGlow), findsOneWidget);
      expect(find.descendant(of: find.byType(ErrorGlow), matching: find.byType(DecoratedBox)), findsOneWidget);
    });

    testWidgets('with motion, SYSTEM_error blooms then breathes, and list rows rise in', (tester) async {
      await pumpFrame(tester, errorTemplate);
      expect([find.byType(Glow), find.byType(TweenAnimationBuilder<double>)], everyElement(findsWidgets));
      expect(tester.hasRunningAnimations, isTrue);
      await pumpFrame(tester, listTemplate);
      expect(find.byType(RiseIn), findsNWidgets(3));
    });
  });

  group('every page fits the full and the compact page box', () {
    for (final template in templatesA) {
      for (final (name, height) in [('full', fullHeight), ('compact', compactHeight)]) {
        testWidgets('$template, $name', (tester) async {
          await pumpFrame(tester, template, height: height);
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull, reason: 'no overflow');
          expect(find.byType(Text), findsWidgets);
        });
      }
    }
  });
}
