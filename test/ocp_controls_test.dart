import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/now_playing_page.dart';
import 'package:ovos_gui_visage/pages/ocp_browse_model.dart';
import 'package:ovos_gui_visage/pages/ocp_list_page.dart';
import 'package:ovos_gui_visage/pages/ocp_model.dart';
import 'package:ovos_gui_visage/pages/ocp_transport.dart';
import 'package:ovos_gui_visage/pages/page.dart';

const ocp = 'ovos.common_play';

Widget host(Widget page) => MaterialApp(
  home: Material(
    child: Center(child: SizedBox(width: 432, height: 650, child: page)),
  ),
);

PageContext recording(String page, List<Json> sent) => PageContext(
  namespace: ocp,
  page: page,
  events: const {},
  send: (message) {
    sent.add(message);
    return true;
  },
);

List<String> names(List<Json> sent) => [for (final m in sent) m['event_name'] as String];

const track = {
  'title': 'A song',
  'artist': 'Someone',
  'status': 'Playing',
  'duration': 200000,
  'position': 0,
  'canPrev': true,
  'canNext': true,
};

const entryA = {'track': 'First', 'album': 'ovos-skill-somafm.openvoiceos', 'uri': 'https://a', 'duration': 0};
const entryB = {'track': 'Second', 'album': 'ovos-skill-somafm.openvoiceos', 'uri': 'https://b', 'duration': 0};

void main() {
  test('play and pause follow the state; a stopped player cannot resume', () {
    expect(playPauseEvent(PlaybackState.playing), 'pause');
    expect(playPauseEvent(PlaybackState.paused), 'resume');
    expect(playPauseEvent(PlaybackState.stopped), isNull);
  });

  test('a seek sends milliseconds, never 0, which the handler would read as no value', () {
    expect(seekParameters(0.5, 200000), {'seekValue': 100000});
    expect(seekParameters(0, 200000), {'seekValue': 1});
    expect(seekParameters(1.4, 200000), {'seekValue': 200000});
  });

  test('only a finite, non-live track can be sought', () {
    expect(canSeek(trackModel(track)), isTrue);
    expect(canSeek(trackModel({...track, 'duration': 0, 'length': 0})), isFalse);
  });

  testWidgets('the transport sends what OVOSSyncPlayer.qml sends', (tester) async {
    final sent = <Json>[];
    await tester.pumpWidget(host(NowPlayingPage.page(track, recording('PlayerLoader', sent))));
    for (final tooltip in ['Previous', 'Pause', 'Stop', 'Next']) {
      await tester.tap(find.byTooltip(tooltip));
    }
    expect(names(sent), ['previous', 'pause', 'stop', 'next']);
    expect(sent.first, {'type': 'mycroft.events.triggered', 'namespace': ocp, 'event_name': 'previous', 'parameters': {}});
    sent.clear();
    await tester.pumpWidget(host(NowPlayingPage.page({...track, 'status': 'Paused'}, recording('PlayerLoader', sent))));
    await tester.tap(find.byTooltip('Play'));
    expect(names(sent), ['resume']);
  });

  testWidgets('without previous or next the buttons are off', (tester) async {
    final sent = <Json>[];
    final data = {...track, 'canPrev': false, 'canNext': false};
    await tester.pumpWidget(host(NowPlayingPage.page(data, recording('PlayerLoader', sent))));
    await tester.tap(find.byTooltip('Previous'));
    await tester.tap(find.byTooltip('Next'));
    expect(sent, isEmpty);
  });

  testWidgets('dragging the seek bar sends one seek where it is let go', (tester) async {
    final sent = <Json>[];
    await tester.pumpWidget(host(NowPlayingPage.page(track, recording('PlayerLoader', sent))));
    final bar = tester.getRect(find.byType(Slider));
    final gesture = await tester.startGesture(Offset(bar.left + 30, bar.center.dy));
    await gesture.moveTo(bar.center);
    await gesture.up();
    await tester.pump();
    expect(names(sent), ['seek']);
    final ms = sent.single['parameters']['seekValue'] as int;
    expect(ms, inInclusiveRange(90000, 110000));
  });

  testWidgets('a live stream has no seek bar', (tester) async {
    await tester.pumpWidget(host(NowPlayingPage.page({...track, 'duration': 0}, recording('PlayerLoader', []))));
    expect(find.byType(Slider), findsNothing);
  });

  test('playlist rows play from the playlist, search results from the search', () {
    final model = suggestionsModel({
      'playlistModel': {
        'data': [entryA],
      },
      'searchModel': {
        'data': [entryA, entryB],
      },
    });
    expect([for (final r in model.rows) r.play?.event], [playlistPlay, searchPlay]);
    expect(model.rows.last.play?.parameters, {'playlistData': entryB});
  });

  testWidgets('a tap on a row sends the entry as Playlist.qml and Disambiguation.qml do', (tester) async {
    final sent = <Json>[];
    final data = {
      'playlistModel': {
        'data': [entryA],
      },
      'searchModel': {
        'data': [entryB],
      },
    };
    await tester.pumpWidget(host(OcpListPage.build_(data, recording('SuggestionsView', sent))));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('First'));
    await tester.tap(find.text('Second'));
    expect(sent, [
      {
        'type': 'mycroft.events.triggered',
        'namespace': ocp,
        'event_name': 'playlist.play',
        'parameters': {'playlistData': entryA},
      },
      {
        'type': 'mycroft.events.triggered',
        'namespace': ocp,
        'event_name': 'search.play',
        'parameters': {'playlistData': entryB},
      },
    ]);
  });

  test('every recorded OCP control is one this app sends, with the shapes it builds', () {
    final trips = [
      for (final line in File('test/fixtures/outgoing/ocp_controls_round_trip.jsonl').readAsLinesSync())
        jsonDecode(line)['sent'] as Json,
    ];
    final events = {ocpPrevious, ocpNext, ocpPause, ocpResume, ocpStop, ocpSeek, playlistPlay, searchPlay};
    expect({for (final t in trips) t['event_name']}, events);
    expect(trips.every((t) => t['namespace'] == ocp), isTrue);
    expect(trips.firstWhere((t) => t['event_name'] == ocpSeek)['parameters'], seekParameters(0.5, 200000));
  });
}
