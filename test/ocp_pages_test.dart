import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/now_playing_page.dart';
import 'package:ovos_gui_visage/pages/ocp_busy_page.dart';
import 'package:ovos_gui_visage/pages/ocp_list_page.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

const ocp = 'ovos.common_play';
PageContext ctx(String page) => PageContext(namespace: ocp, page: page, events: const {});

Widget host(Widget page) => MaterialApp(home: Material(child: Center(child: SizedBox(width: 432, height: 736, child: page))));

/// OCP's data each time a given page was on screen in a fixture, in order (distinct states only).
List<Json> statesOf(String fixture, String page) {
  final state = GuiState();
  final states = <Json>[];
  for (final line in File('test/fixtures/$fixture').readAsLinesSync()) {
    if (line.trim().isEmpty) continue;
    state.apply(jsonDecode(line) as Json);
    final current = state.current();
    if (current?.namespace == ocp && current?.page == page) {
      final data = jsonDecode(jsonEncode(state.namespace(ocp).data)) as Json;
      if (states.isEmpty || jsonEncode(states.last) != jsonEncode(data)) states.add(data);
    }
  }
  return states;
}

void main() {
  test('OCP pages are routed', () {
    expect(resolve(const Target(ocp, 'PlayerLoader', 0))({}, ctx('PlayerLoader')), isA<NowPlayingPage>());
    expect(resolve(const Target(ocp, 'busy', 0))({}, ctx('busy')), isA<OcpBusyPage>());
    expect(resolve(const Target(ocp, 'Home', 0))({}, ctx('Home')), isA<OcpListPage>());
  });

  testWidgets('the recorded play/pause/resume/stop session drives the player through its states', (tester) async {
    final states = statesOf('ocp_play_pause_resume_stop.jsonl', 'PlayerLoader');
    expect(states.map((s) => s['status']).toSet(), containsAll(['Playing', 'Paused', 'Stopped']));
    for (final data in states) {
      await tester.pumpWidget(host(NowPlayingPage.page(data, ctx('PlayerLoader'))));
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
      final status = data['status'] as String?;
      if (status != null) expect(find.text(status.toLowerCase()), findsOneWidget);
    }
    final title = states.last['title'] as String?;
    expect(find.text(title ?? 'Unknown track'), findsOneWidget);
  });

  testWidgets('a non-sync backend gets the fallback card', (tester) async {
    await tester.pumpWidget(host(NowPlayingPage.page({'playerBackend': 'OVOSWebPlayer', 'title': 'x'}, ctx('PlayerLoader'))));
    expect(find.byType(FallbackPage), findsOneWidget);
  });

  testWidgets('a live stream shows elapsed time and the live word', (tester) async {
    final data = {'title': 'Groove Salad', 'artist': 'SomaFM', 'status': 'Playing', 'duration': 0, 'position': 14, 'length': 43284};
    await tester.pumpWidget(host(NowPlayingPage.page(data, ctx('PlayerLoader'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('0:14 · live'), findsOneWidget);
    expect(find.text('SomaFM'), findsOneWidget);
  });

  testWidgets('the recorded SomaFM browse shows suggestions and home', (tester) async {
    final suggestions = statesOf('ocp_somafm_live_browse.jsonl', 'SuggestionsView');
    expect(suggestions, isNotEmpty);
    await tester.pumpWidget(host(OcpListPage.build_(suggestions.last, ctx('SuggestionsView'))));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    final home = statesOf('ocp_somafm_live_browse.jsonl', 'Home');
    expect(home, isNotEmpty);
    await tester.pumpWidget(host(OcpListPage.build_(home.last, ctx('Home'))));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('MEDIA'), findsOneWidget);
  });

  testWidgets('busy shows the label', (tester) async {
    await tester.pumpWidget(host(OcpBusyPage.page({'footer_text': 'Searching...'}, ctx('busy'))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Searching...'), findsOneWidget);
  });
}
