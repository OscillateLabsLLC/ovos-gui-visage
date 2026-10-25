import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/media_keys.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/protocol/gui1_frames.dart';
import 'package:ovos_gui_visage/protocol/gui_events.dart';
import 'package:ovos_gui_visage/state/gui1_apply.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

/// The frames up to and including the first `template`: what the display shows first.
int _firstShow(List<Gui1Frame> frames) => frames.indexWhere((f) => f is Gui1Template) + 1;

/// The page for the state's top namespace, with every trigger recorded in [sent].
Widget recordedPage(GuiState state, List<Json> sent) {
  final target = state.current()!;
  final ctx = PageContext(
    namespace: target.namespace,
    page: target.page,
    events: const {},
    send: (message) {
      sent.add(message);
      return true;
    },
  );
  return host(resolve(target, gaps: TemplateGaps())(state.namespace(target.namespace).data, ctx));
}

/// Shows a fixture's first template, checks it, then applies each later frame and checks again.
Future<void> playFixture(WidgetTester tester, String name, List<Json> sent, List<void Function()> checks) async {
  final frames = loadGui1Fixture(name);
  final shown = _firstShow(frames);
  final state = replayGui1(frames.sublist(0, shown));
  await tester.pumpWidget(recordedPage(state, sent));
  checks.first();
  for (final (i, frame) in frames.sublist(shown).indexed) {
    applyGui1Frame(state, frame, gaps: freshGaps());
    await tester.pumpWidget(recordedPage(state, sent));
    await tester.pump(const Duration(milliseconds: 100));
    checks[i + 1]();
  }
}

Set<String> recordedBusTypes() => {
  for (final line in File('test/fixtures/outgoing/ocp_controls_round_trip.jsonl').readAsLinesSync())
    jsonDecode(line)['bus']['type'] as String,
};

Json fixtureData(String name) => loadGui1Fixture(name).whereType<Gui1Template>().first.data;

void main() {
  setUp(forgetMediaFaults);

  testWidgets('system_audio_player: the now-playing card, then an update that pauses it further on', (tester) async {
    final sent = <Json>[];
    final faults = await collectFaults(
      () => playFixture(tester, 'system_audio_player', sent, [
        () {
          expect(find.text('Morning Briefing'), findsOneWidget);
          expect(find.text('Public Radio · News Hour'), findsOneWidget);
          expect(find.text('playing'), findsOneWidget);
          expect(find.text('1:30 / 5:00'), findsOneWidget);
          expect(find.byType(Slider), findsOneWidget);
        },
        () {
          expect(find.text('paused'), findsOneWidget);
          expect(find.text('2:30 / 5:00'), findsOneWidget);
        },
      ]),
    );
    expect(faults, isEmpty);
  });

  testWidgets('the audio transport answers in OCP\'s namespace with recorded messages, not in the app\'s', (tester) async {
    final sent = <Json>[];
    final state = replayGui1(loadGui1Fixture('system_audio_player').sublist(0, 5));
    expect(state.current()!.namespace, 'ovos-skill-news.openvoiceos');
    await tester.pumpWidget(recordedPage(state, sent));
    await tester.tap(find.byTooltip('Pause'));
    await tester.tap(find.byTooltip('Stop'));
    expect([for (final m in sent) busMessageFor(m)['type']], ['ovos.common_play.pause', 'ovos.common_play.stop']);
    expect(recordedBusTypes(), containsAll([for (final m in sent) busMessageFor(m)['type']]));
  });

  testWidgets('a live audio stream shows no seek bar', (tester) async {
    final state = GuiState();
    applyGui1Frame(state, template(hello, 'SYSTEM_audio_player', {...fixtureData('system_audio_player'), 'duration': -1}));
    await tester.pumpWidget(recordedPage(state, []));
    expect(find.byType(Slider), findsNothing);
    expect(find.textContaining('live'), findsOneWidget);
  });

  testWidgets('system_audio_player degrades: no title and a string position are reported, the card still shows', (tester) async {
    final data = Json.of(fixtureData('system_audio_player'))
      ..remove('title')
      ..['position'] = '90';
    final faults = await collectFaults(() async {
      final state = GuiState();
      applyGui1Frame(state, template(hello, 'SYSTEM_audio_player', data));
      await tester.pumpWidget(recordedPage(state, []));
    });
    expect(find.text('Unknown track'), findsOneWidget);
    expect(find.text('Public Radio · News Hour'), findsOneWidget);
    expect(
      [for (final f in faults) '${f.exception}'],
      [contains('title is required'), contains('position must be a finite number')],
    );
  });

  testWidgets('system_video_player: a still with the title, then paused', (tester) async {
    final faults = await collectFaults(
      () => playFixture(tester, 'system_video_player', [], [
        () {
          expect(find.text('Big Buck Bunny'), findsOneWidget);
          expect(find.text('playing'), findsOneWidget);
          expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
        },
        () => expect(find.text('paused'), findsOneWidget),
      ]),
    );
    expect(faults, isEmpty);
  });

  testWidgets('system_video_player degrades: no uri is reported, the title still shows', (tester) async {
    final faults = await collectFaults(() async {
      final state = GuiState();
      applyGui1Frame(state, template(hello, 'SYSTEM_video_player', {'title': 'Big Buck Bunny'}));
      await tester.pumpWidget(recordedPage(state, []));
    });
    expect(find.text('Big Buck Bunny'), findsOneWidget);
    expect([for (final f in faults) '${f.exception}'], [contains('uri is required')]);
  });

  testWidgets('system_media_player: now playing, an update that pauses further on, then loading the next track', (tester) async {
    final faults = await collectFaults(
      () => playFixture(tester, 'system_media_player', [], [
        () {
          expect(find.text('Blue in Green'), findsOneWidget);
          expect(find.text('Miles Davis · Kind of Blue'), findsOneWidget);
          expect(find.text('0:30 / 5:37'), findsOneWidget);
          expect(
            [
              for (final l in ['NOW PLAYING', 'RESULTS', 'QUEUE']) find.text(l).evaluate().length,
            ],
            [1, 1, 1],
          );
        },
        () {
          expect(find.text('paused'), findsOneWidget);
          expect(find.text('2:00 / 5:37'), findsOneWidget);
        },
        () => expect(find.text('Loading So What'), findsOneWidget),
      ]),
    );
    expect(faults, isEmpty);
  });

  testWidgets('system_media_player: the queue and results views, chosen with plain buttons that send nothing', (tester) async {
    final sent = <Json>[];
    final state = replayGui1(loadGui1Fixture('system_media_player').sublist(0, 5));
    await tester.pumpWidget(recordedPage(state, sent));
    await tester.tap(find.text('QUEUE'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Groove Salad'), findsOneWidget);
    expect(find.text('Miles Davis · 9:22'), findsOneWidget);
    await tester.tap(find.text('So What'));
    await tester.tap(find.text('RESULTS'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Miles Davis · local media'), findsOneWidget);
    expect(sent, isEmpty);
  });

  testWidgets('system_media_player degrades: a capitalised state and a bad playlist are reported, now playing still shows', (
    tester,
  ) async {
    final data = {...fixtureData('system_media_player'), 'media_playback_state': 'Playing', 'media_playlist': 'nope'};
    final faults = await collectFaults(() async {
      final state = GuiState();
      applyGui1Frame(state, template('ovos.common_play', 'SYSTEM_media_player', data));
      await tester.pumpWidget(recordedPage(state, []));
    });
    expect(find.text('Blue in Green'), findsOneWidget);
    expect(find.text('playing'), findsOneWidget);
    final reports = [for (final f in faults) '${f.exception}'];
    expect(reports, containsAll([contains('media_playback_state must be'), contains('media_playlist must be an array')]));
  });
}
