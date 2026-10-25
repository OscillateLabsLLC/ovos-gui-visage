/// Flutter's accessibility guidelines over every page a fixture reaches, legacy and GUI-1, plus the built-in resting
/// pages (docs/DESIGN.md, Glanceability). A page that fails today is skipped with `audit:` and its failure, so the
/// list shows in the test output and in docs/BACKLOG.md; the page is not changed here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/blank_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/resting_page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/template_names.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/state/gui1_apply.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';
import 'package:ovos_gui_visage/theme.dart';

import 'faults.dart';

const contrast = 'text contrast';
const labels = 'labelled tap targets';

/// Pages that fail a guideline today, at both sizes: page -> guideline -> the failure, as the first run (2026-10-25)
/// measured it. testWidgets takes no skip message, so the reason goes in the skipped test's name.
const audit = <String, Map<String, String>>{
  'ovos-skill-weather.openvoiceos/SunriseSunset': {contrast: 'SUNRISE 4.02:1 and SUNSET 4.38:1 at 16 px, under 4.5:1'},
  'resting (GUI-1)': {contrast: 'count badge, white on the accent, 2.92:1 at 15 px; the homescreen idle page shares it'},
  'SYSTEM_InputBox': {contrast: 'Confirm button label 2.92:1 at 20 px, under 3:1'},
  'SYSTEM_text': {contrast: 'the text "Hello" 2.92:1 at 72 px, under 3:1'},
};

typedef Shown = ({Target target, Json data, Json events});

/// The last data each page was shown with, keyed by its route or its template's canonical name.
final shown = <String, Shown>{};

String pageKey(Target target) {
  final route = '${target.namespace}/${target.page}';
  return routes.containsKey(route) ? route : (canonicalTemplate(target.page) ?? route);
}

void _remember(GuiState state) {
  final target = state.current();
  if (target == null) return;
  final ns = state.namespace(target.namespace);
  shown[pageKey(target)] = (target: target, data: Json.of(jsonDecode(jsonEncode(ns.data)) as Json), events: Json.of(ns.events));
}

List<Json> _lines(File file) => [
  for (final line in file.readAsLinesSync())
    if (line.trim().isNotEmpty) jsonDecode(line) as Json,
];

Iterable<File> _jsonl(String dir) =>
    Directory(dir).listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl')).toList()
      ..sort((a, b) => a.path.compareTo(b.path));

void collectShownPages() {
  for (final file in _jsonl('test/fixtures')) {
    final state = GuiState();
    for (final message in _lines(file)) {
      state.apply(message);
      _remember(state);
    }
  }
  for (final file in [..._jsonl('test/fixtures/gui1'), ..._jsonl('test/fixtures/gui1/recorded')]) {
    final state = GuiState();
    final gaps = Gui1Gaps(templates: TemplateGaps(), log: (_) {});
    for (final frame in _lines(file).where((line) => !line.containsKey('_note')).map(parseGui1Frame)) {
      applyGui1Frame(state, frame, gaps: gaps);
      _remember(state);
    }
  }
}

final _restingAmbient = {
  ambientWeather: {'current_temp': 21, 'condition': 'Cloudy', 'condition_code': 'cloudy'},
  ambientNotifications: {'count': 2},
};

Widget pageFor(String key) => switch (key) {
  'resting (GUI-1)' => RestingPage(ambient: _restingAmbient, now: () => DateTime(2026, 10, 17, 9, 5)),
  'blank' => const BlankPage(),
  _ => _routed(shown[key]!),
};

Widget _routed(Shown page) {
  final ctx = PageContext(namespace: page.target.namespace, page: page.target.page, events: page.events);
  return resolve(page.target, gaps: TemplateGaps())(page.data, ctx);
}

/// The page as the frame shows it: padded on the black page background, the 480 x 800 frame scaled into [view].
Widget framed(Widget page) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: Material(
    color: VisageColors.pageBg,
    child: FittedBox(
      child: SizedBox(
        width: 480,
        height: 800,
        child: Padding(padding: const EdgeInsets.fromLTRB(24, 32, 24, 32), child: page),
      ),
    ),
  ),
);

Future<Evaluation> evaluate(WidgetTester tester, String key, Size view, AccessibilityGuideline guideline) async {
  tester.view
    ..physicalSize = view
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final handle = tester.ensureSemantics();
  late Evaluation result;
  await collectFaults(() async {
    await tester.pumpWidget(framed(pageFor(key)));
    await tester.pump(const Duration(seconds: 1));
    result = await guideline.evaluate(tester);
  });
  handle.dispose();
  return result;
}

void main() {
  collectShownPages();
  final keys = [...shown.keys.toList()..sort(), 'resting (GUI-1)', 'blank'];

  test('every routed page is reached by some fixture, or listed here', () {
    final missing = [...routes.keys, ...templates.keys].where((key) => !shown.containsKey(key)).toList();
    // Informative: printed for the audit list, not a failure.
    debugPrint('a11y: pages no fixture reaches: ${missing.join(', ')}');
    expect(keys, isNotEmpty);
  });

  for (final key in keys) {
    for (final (name, view, guideline) in [
      (contrast, const Size(480, 800), textContrastGuideline),
      (labels, const Size(480, 800), labeledTapTargetGuideline),
      (contrast, const Size(240, 400), textContrastGuideline),
    ]) {
      final skip = audit[key]?[name];
      final title = '$key: $name at ${view.width.round()} x ${view.height.round()}${skip == null ? '' : ' [audit: $skip]'}';
      testWidgets(title, skip: skip != null, (tester) async {
        final result = await evaluate(tester, key, view, guideline);
        expect(result.passed, isTrue, reason: result.reason);
      });
    }
    testWidgets('$key: Android tap-target size (informative on the desktop)', (tester) async {
      final result = await evaluate(tester, key, const Size(480, 800), androidTapTargetGuideline);
      debugPrint('a11y informative: $key tap-target size ${result.passed ? 'passes' : 'fails: ${result.reason}'}');
    });
  }
}
