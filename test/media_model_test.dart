import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/media_browse_model.dart';
import 'package:ovos_gui_visage/pages/media_keys.dart';
import 'package:ovos_gui_visage/pages/media_model.dart';
import 'package:ovos_gui_visage/pages/ocp_model.dart';
import 'package:ovos_gui_visage/pages/ocp_transport.dart';

import 'faults.dart';

const cover = 'data:image/png;base64,AAAA';
const audio = {
  'title': 'Morning Briefing',
  'artist': 'Public Radio',
  'album': 'News Hour',
  'image': cover,
  'position': 90000,
  'duration': 300000,
  'playing': true,
};
const queue = [
  {'title': 'Groove Salad', 'artist': 'SomaFM', 'uri': 'https://a', 'duration': -1},
  {'title': 'Blue in Green', 'artist': 'Miles Davis', 'uri': 'https://b', 'duration': 337000},
  {'title': 'So What', 'artist': 'Miles Davis', 'uri': 'https://c', 'duration': 562000},
];
const results = [
  {'title': 'Kind of Blue', 'artist': 'Miles Davis', 'uri': 'https://k', 'skill_id': 'ovos-skill-local-media.openvoiceos'},
];
const media = {
  'media_title': 'Blue in Green',
  'media_artist': 'Miles Davis',
  'media_uri': 'https://b',
  'media_position': 30000,
  'media_duration': 337000,
  'media_playback_state': 'playing',
  'media_playlist': queue,
  'media_search_results': results,
  'media_playlist_position': 1,
};

Json without(Json data, String key) => Json.of(data)..remove(key);

Future<List<String>> faultsOf(void Function() body) async => [
  for (final f in await collectFaults(() async => body())) '${f.exception}',
];

void main() {
  setUp(forgetMediaFaults);

  group('SYSTEM_audio_player', () {
    test('reads every key in milliseconds onto the now-playing track', () async {
      late Track track;
      expect(await faultsOf(() => track = audioTrack(audio)), isEmpty);
      expect(
        (track.title, track.artist, track.cover, track.state),
        ('Morning Briefing', 'Public Radio · News Hour', cover, PlaybackState.playing),
      );
      expect((track.positionMs, track.durationMs, track.live), (90000, 300000, false));
      final progress = progressAt(track);
      expect((progress.elapsed, progress.total, progress.fraction), ('1:30', '5:00', 0.3));
      expect(canSeek(track), isTrue);
    });

    test('GUI-1 position is ms; legacy OCP position is seconds; both show 1:30', () {
      expect(audioTrack({...audio, 'position': 90000}).positionMs, 90000);
      expect(audioTrack({...audio, 'position': 90}).positionMs, 90);
      final legacy = trackModel({'title': 'x', 'status': 'Playing', 'position': 90, 'duration': 300000});
      expect(progressAt(legacy).elapsed, '1:30');
    });

    test('-1 and an omitted duration are unknown or live: no seek bar, no fault', () async {
      final faults = await faultsOf(() {
        for (final data in [
          {...audio, 'duration': -1},
          without(audio, 'duration'),
        ]) {
          final track = audioTrack(data);
          expect((track.live, canSeek(track), progressAt(track).total), (true, false, 'live'));
        }
      });
      expect(faults, isEmpty);
    });

    test('a position of -1 is unknown and starts at 0 unreported; any other negative position is reported', () async {
      late Track unknown, negative;
      final faults = await faultsOf(() {
        unknown = audioTrack({...audio, 'position': -1});
        negative = audioTrack({...audio, 'position': -5});
      });
      expect((unknown.positionMs, negative.positionMs), (0, 0));
      expect(faults, [contains('position must not be negative')]);
    });

    test('optional keys can be missing; playing omitted reads as paused', () async {
      late Track track;
      expect(await faultsOf(() => track = audioTrack({'title': 'Only a title'})), isEmpty);
      expect((track.artist, track.cover, track.state, track.positionMs), ('', null, PlaybackState.paused, 0));
      expect(audioTrack({...audio, 'playing': false}).state, PlaybackState.paused);
    });

    test('a missing title is reported and the track still shows', () async {
      late Track track;
      final faults = await faultsOf(() => track = audioTrack(without(audio, 'title')));
      expect(faults, [contains('title is required')]);
      expect((track.title, track.artist), ('Unknown track', 'Public Radio · News Hour'));
    });

    test('wrong types are reported once each and read as absent or coerced', () async {
      const bad = {'title': 42, 'position': '90', 'duration': 0, 'playing': 'yes', 'image': '/home/me/cover.png'};
      late Track track;
      final faults = await faultsOf(() {
        track = audioTrack(bad);
        audioTrack(bad);
      });
      expect(faults, hasLength(5));
      expect(faults.join('\n'), allOf(contains('title must be a string'), contains('position must be a finite number')));
      expect(
        faults.join('\n'),
        allOf(contains('duration must be positive'), contains('playing must be a boolean'), contains('data: URI')),
      );
      expect((track.title, track.positionMs, track.live, track.cover), ('42', 0, true, null));
    });
  });

  group('SYSTEM_video_player', () {
    test('title and play state; with no title the uri names it', () async {
      final faults = await faultsOf(() {
        expect(videoModel({'uri': 'https://x/v/big_buck_bunny.mp4', 'title': 'Bunny', 'playing': true}), (
          title: 'Bunny',
          state: PlaybackState.playing,
        ));
        expect(videoModel({'uri': 'https://x/v/big%20buck.mp4'}).title, 'big buck.mp4');
      });
      expect(faults, isEmpty);
    });

    test('a missing uri is reported and the title still shows', () async {
      late VideoModel model;
      final faults = await faultsOf(() => model = videoModel({'title': 'Bunny', 'playing': false}));
      expect(faults, [contains('uri is required')]);
      expect(model, (title: 'Bunny', state: PlaybackState.paused));
    });
  });

  group('SYSTEM_media_player', () {
    test('media_* keys fill the same track; the queue position offers previous and next', () async {
      late Track track;
      expect(await faultsOf(() => track = mediaTrack(media)), isEmpty);
      expect((track.title, track.artist, track.positionMs, track.durationMs), ('Blue in Green', 'Miles Davis', 30000, 337000));
      expect((track.state, track.canPrev, track.canNext), (PlaybackState.playing, true, true));
      final first = mediaTrack({...media, 'media_playlist_position': 0});
      expect((first.canPrev, first.canNext), (false, true));
    });

    test('playback states: stopped stops, omitted reads as paused, a capitalised OCP status is reported', () async {
      expect(mediaTrack({...media, 'media_playback_state': 'stopped'}).state, PlaybackState.stopped);
      expect(mediaTrack(without(media, 'media_playback_state')).state, PlaybackState.paused);
      late Track track;
      final faults = await faultsOf(() => track = mediaTrack({...media, 'media_playback_state': 'Playing'}));
      expect(faults, [contains('media_playback_state must be playing, paused, stopped, loading or error')]);
      expect(track.state, PlaybackState.playing);
    });

    test('an out-of-range position and a non-array playlist are reported', () async {
      late Track track;
      final faults = await faultsOf(() {
        track = mediaTrack({...media, 'media_playlist_position': 3});
        mediaTrack({...media, 'media_playlist': 'nope'});
      });
      expect(faults, [contains('media_playlist_position must be a 0-based index'), contains('media_playlist must be an array')]);
      expect((track.canPrev, track.canNext), (false, false));
    });

    test('views: the state view first, then results, then queue; nothing at all is empty', () {
      final [now, res, que] = [MediaView.nowPlaying, MediaView.results, MediaView.queue];
      expect(mediaViews(media), [now, res, que]);
      expect(mediaViews({...media, 'media_playback_state': 'loading'}), [MediaView.loading, res, que]);
      expect(mediaViews({...media, 'media_playback_state': 'error'}), [MediaView.error, res, que]);
      expect(mediaViews(without(without(media, 'media_search_results'), 'media_playlist')), [now]);
      expect(mediaViews({'media_playback_state': 'stopped'}), [MediaView.empty]);
      expect(mediaStateLabel(media, MediaView.loading), 'Loading Blue in Green');
      expect(mediaStateLabel(const {}, MediaView.error), 'Could not play the media');
    });

    test('the queue marks the entry at the position, else the one at media_uri; rows cannot be tapped', () {
      final model = queueModel(media);
      expect(model.heading, 'Queue');
      expect(
        [for (final r in model.rows) (r.title, r.subtitle, r.current)],
        [
          ('Groove Salad', 'SomaFM', false),
          ('Blue in Green', 'Miles Davis · 5:37', true),
          ('So What', 'Miles Davis · 9:22', false),
        ],
      );
      expect(model.rows.every((r) => r.play == null), isTrue);
      final byUri = queueModel({...without(media, 'media_playlist_position'), 'media_uri': 'https://c'});
      expect([for (final r in byUri.rows) r.current], [false, false, true]);
    });

    test('search results name the skill that found each', () {
      final model = resultsModel(media);
      expect((model.heading, model.rows.single.subtitle), ('Search results', 'Miles Davis · local media'));
    });

    test('an entry image that is a path is reported and dropped', () async {
      late List<String?> covers;
      final faults = await faultsOf(() {
        final data = {
          ...media,
          'media_playlist': [
            {'title': 'a', 'image': '/tmp/a.png'},
            {'title': 'b', 'image': cover},
          ],
        };
        covers = [for (final r in queueModel(data).rows) r.cover];
      });
      expect(faults, [contains('media_playlist entry image must be an http(s) URL or a data: URI')]);
      expect(covers, [null, cover]);
    });
  });
}
