import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/clock_page.dart';
import 'package:ovos_gui_visage/pages/error_page.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/grid_page.dart';
import 'package:ovos_gui_visage/pages/html_frame_page.dart';
import 'package:ovos_gui_visage/pages/image_frame_page.dart';
import 'package:ovos_gui_visage/pages/list_page.dart';
import 'package:ovos_gui_visage/pages/loading_page.dart';
import 'package:ovos_gui_visage/pages/map_page.dart';
import 'package:ovos_gui_visage/pages/media_keys.dart';
import 'package:ovos_gui_visage/pages/media_pages.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/status_page.dart';
import 'package:ovos_gui_visage/pages/system_face_page.dart';
import 'package:ovos_gui_visage/pages/system_timer_page.dart';
import 'package:ovos_gui_visage/pages/system_weather_page.dart';
import 'package:ovos_gui_visage/pages/table_page.dart';
import 'package:ovos_gui_visage/pages/template_keys.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';
import 'package:ovos_gui_visage/pages/url_frame_page.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/state/ambient.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const demo = 'ovos-skill-gui1-demo.oscillatelabs';

/// Each single-template recording, by file name: the template the skill showed and the page the router registers for it,
/// in catalogue order, which is the order `run the gui demo` shows them.
const catalogue = <String, (String, Type)>{
  'loading': ('SYSTEM_loading', LoadingPage),
  'status': ('SYSTEM_status', StatusPage),
  'error': ('SYSTEM_error', ErrorPage),
  'text': ('SYSTEM_text', TextFramePage),
  'image': ('SYSTEM_image', ImageFramePage),
  'animated_image': ('SYSTEM_animated_image', ImageFramePage),
  'list': ('SYSTEM_list', ListPage),
  'grid': ('SYSTEM_grid', GridPage),
  'table': ('SYSTEM_table', TablePage),
  'html': ('SYSTEM_html', HtmlFramePage),
  'url': ('SYSTEM_url', UrlFramePage),
  'audio_player': ('SYSTEM_audio_player', AudioPlayerPage),
  'video_player': ('SYSTEM_video_player', VideoPlayerPage),
  'media_player': ('SYSTEM_media_player', MediaPlayerPage),
  'clock': ('SYSTEM_clock', ClockPage),
  'timer': ('SYSTEM_timer', SystemTimerPage),
  'weather': ('SYSTEM_weather', SystemWeatherPage),
  'map': ('SYSTEM_map', MapPage),
  'face': ('SYSTEM_face', SystemFacePage),
};

const scenarios = ['full_demo', 'degradation', 'update', 'ambient', 'stop_intent', 'stop_global'];

/// The frames up to the skill's deactivation: what the screen shows while the template is up.
List<Gui1Frame> whileShown(List<Gui1Frame> frames) => frames.takeWhile((f) => f is! Gui1Deactivated).toList();

/// The 480 x 800 frame, so `host`'s page box is not cut down to the test runner's default 800 x 600 view.
void frameSized(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(480, 800)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pumps [state]'s page through the router as the GUI-1 window renders it, expects a [shows] page, and returns what it
/// reported; then unmounts it so no ticker or timer outlives the test.
Future<List<FlutterErrorDetails>> pumpRouted(
  WidgetTester tester,
  GuiState state,
  TemplateGaps gaps, {
  required Type shows,
}) async {
  frameSized(tester);
  final faults = await collectFaults(() async {
    await tester.pumpWidget(host(pageOf(state, gaps: gaps, protocol: ChosenProtocol.gui1)));
    await tester.pump(const Duration(milliseconds: 100));
  });
  expect(find.byType(shows), findsOneWidget);
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  return faults;
}

String described(FlutterErrorDetails fault) => '${fault.context?.toDescription()}: ${fault.exceptionAsString()}';

void main() {
  setUp(() {
    forgetReportedKeys();
    forgetMediaFaults();
  });

  test('the demo skill recorded 25 fixtures, each with its note, and every one parses', () {
    final files = Directory('test/fixtures/gui1/recorded/demo')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jsonl'));
    final names = files.map((f) => f.uri.pathSegments.last.replaceAll('.jsonl', '')).toSet();
    expect(names, {...catalogue.keys, ...scenarios});
    expect(files, hasLength(25));
    for (final name in names) {
      expect(loadDemo(name), isNotEmpty, reason: name);
    }
  });

  group('one template', () {
    for (final MapEntry(key: name, value: (template, page)) in catalogue.entries) {
      testWidgets('$name: shows $template in the skill namespace, routed to $page, with no fault', (tester) async {
        final gaps = freshGaps();
        final state = replayGui1(whileShown(loadDemo(name)), gaps: gaps);
        expect(state.current(), Target(demo, template, 0));
        expect(resolve(state.current(), gaps: gaps.templates), same(templates[template]));
        final faults = await pumpRouted(tester, state, gaps.templates, shows: page);
        expect(faults.map(described), isEmpty);
      });
    }

    test('media_player: the second session_update moves the position and keeps the template', () {
      final state = replayGui1(whileShown(loadDemo('media_player')));
      expect(state.current(), const Target(demo, 'SYSTEM_media_player', 0));
      expect(state.namespace(demo).data['media_position'], 4000);
    });

    test('each recording ends with its namespace gone and the session idle', () {
      for (final name in catalogue.keys) {
        final state = replayGui1(loadDemo(name));
        expect([state.active, state.namespaces], [isEmpty, isEmpty], reason: name);
      }
    });
  });

  group('scenarios', () {
    test('full_demo: the 19 templates in catalogue order, each cleared first, and the stack ends empty (F42)', () {
      final frames = loadDemo('full_demo');
      final shown = [
        for (final frame in frames)
          if (frame is Gui1Template) frame.template,
      ];
      expect(shown, [for (final (template, _) in catalogue.values) template]);
      expect(frames.whereType<Gui1Idle>(), hasLength(19), reason: 'an idle for the session between templates');
      final state = replayGui1(frames);
      expect([state.active, state.namespaces], [isEmpty, isEmpty]);
    });

    test('update: one gui.value.set changes the text, and the null removes title', () {
      final frames = whileShown(loadDemo('update')).where((f) => f is! Gui1Status).toList();
      final updates = frames.whereType<Gui1SessionUpdate>().length;
      final before = replayGui1(frames.take(3).toList());
      expect(before.namespace(demo).data, {'title': 'Update demo', 'text': 'This text will change.'});
      final changed = replayGui1(frames.take(4).toList());
      expect(changed.namespace(demo).data['text'], 'The text changed with one gui.value.set.');
      final after = replayGui1(frames);
      expect(after.current(), const Target(demo, 'SYSTEM_text', 0));
      expect(after.namespace(demo).data, {'text': 'The text changed with one gui.value.set.'});
      expect(updates, 3);
    });

    test('ambient: the weather and the last count are kept, and no namespace is made (F40)', () async {
      late GuiState state;
      final faults = await collectFaults(() async => state = replayGui1(loadDemo('ambient')));
      expect(faults.map(described), isEmpty);
      expect(state.ambient[ambientWeather], containsPair('current_temp', 24));
      expect(state.ambient[ambientWeather], containsPair('condition_code', 'clear'));
      expect(state.ambient[ambientNotifications], {'__from': demo, 'count': 0});
      expect([state.active, state.namespaces], [isEmpty, isEmpty]);
    });

    for (final (name, template) in [('stop_intent', 'SYSTEM_text'), ('stop_global', 'SYSTEM_clock')]) {
      test('$name: $template shows, then the stop empties the stack', () {
        final frames = loadDemo(name);
        expect(replayGui1(whileShown(frames)).current(), Target(demo, template, 0));
        final state = replayGui1(frames);
        expect([state.active, state.namespaces, state.current()], [isEmpty, isEmpty, isNull]);
      });
    }
  });

  degradation();
}

/// Each degraded template, by the `title` the demo skill gave it, and the exact reports Visage makes for it over GUI-1.
/// The live window (d7b332b) printed these six as its fault lines during "show the broken gui demo", one each.
const planted = <String, List<String>>{
  'Fault: missing required key text': ['SYSTEM_text data: FormatException: text is required'],
  'Fault: current_temp is a string': [
    'SYSTEM_weather data: FormatException: current_temp must be a finite number, got String seventy two',
  ],
  'Fault: bare file path as image': [
    'SYSTEM_image data: FormatException: image must be an http(s) URL or a data:image URI (gui-1.md 3.5 Image delivery), '
        'got /usr/share/pixmaps/gui1-demo.png',
  ],
  'Fault: table row of the wrong length': ['SYSTEM_table data: FormatException: rows[1] has 2 cells for 3 columns'],
  'Fault: unlisted condition_code': [
    'SYSTEM_weather data: FormatException: condition_code "volcanic_ash" is not in the closed set, so it is ignored',
  ],
  'Fault: unknown template SYSTEM_hologram': [
    'routing SYSTEM_hologram: Invalid argument (template): not a GUI-1 template: "SYSTEM_hologram"',
  ],
};

void degradation() {
  testWidgets('degradation: each planted fault is reported exactly, and the page still renders (F36, F38)', (tester) async {
    frameSized(tester);
    final gaps = freshGaps();
    final state = GuiState();
    final reported = <String, List<String>>{};
    for (final frame in loadDemo('degradation')) {
      final faults = await collectFaults(() async {
        replayGui1([frame], gaps: gaps, state: state);
        if (frame is! Gui1Template) return;
        await tester.pumpWidget(host(pageOf(state, gaps: gaps.templates, protocol: ChosenProtocol.gui1)));
        await tester.pump(const Duration(milliseconds: 100));
      });
      if (frame is Gui1Template) reported[frame.data['title'] as String] = faults.map(described).toList();
      if (frame is! Gui1Template) expect(faults.map(described), isEmpty, reason: '$frame');
    }
    expect(reported, planted);
    expect(find.byType(FallbackPage), findsOneWidget, reason: 'SYSTEM_hologram, the last template, degrades to the fallback');
    await tester.pumpWidget(const SizedBox());
  });
}
