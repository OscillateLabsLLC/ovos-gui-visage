// Port of tests/js/ocp_model.test.mjs.
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/json.dart';
import 'package:ovos_gui_visage/pages/ocp_model.dart';

const song = <String, dynamic>{
  'uri': 'https://x/song.mp3',
  'title': 'Song',
  'artist': 'Band',
  'status': 'Playing',
  'duration': '200000',
  'position': 0,
};

void main() {
  test('cover art: URLs and (same-host) paths are candidates; empty is none', () {
    expect(coverUrl('https://somafm.com/img3/groovesalad-400.jpg'), 'https://somafm.com/img3/groovesalad-400.jpg');
    expect(coverUrl('data:image/png;base64,AAAA'), 'data:image/png;base64,AAAA');
    expect(coverUrl('/res/ovos.common_play/cover.png'), '/res/ovos.common_play/cover.png');
    expect(coverUrl('/home/ovos/.venvs/ovos/lib/ocp.png'), '/home/ovos/.venvs/ovos/lib/ocp.png');
    expect(coverUrl(''), isNull);
    expect(coverUrl(null), isNull);
    expect(coverUrl('relative.png'), isNull);
  });

  test('status words, times and backends', () {
    expect(['Playing', 'Paused', 'Stopped', null, 'weird'].map(playbackState), [
      PlaybackState.playing,
      PlaybackState.paused,
      PlaybackState.stopped,
      PlaybackState.stopped,
      PlaybackState.stopped,
    ]);
    expect([0, 5400, 65000, 213000, 3725000].map(formatTime), ['0:00', '0:05', '1:05', '3:33', '1:02:05']);
    expect(isSyncPlayer({'playerBackend': 'OVOSSyncPlayer'}), isTrue);
    expect(isSyncPlayer({'playerBackend': 'OVOSWebPlayer'}), isFalse);
    expect(isSyncPlayer({}), isTrue);
  });

  test("the track's own duration is the total; the seekbar length never is", () {
    expect(trackModel({...song, 'length': 180000}).durationMs, 200000);
    expect(trackModel({...song, 'duration': '0'}).live, isTrue);
    expect(trackModel({}).title, 'Unknown track');
  });

  test('measured finite track: position in seconds, duration and length in ms', () {
    final moonlight = {...song, 'duration': 339000, 'length': 338561};
    final reports = [33.56, 35.56, 37.6, 39.64].map((p) => trackModel({...moonlight, 'position': p})).toList();
    expect(reports.map((t) => t.positionMs), [33560, 35560, 37600, 39640]);
    expect(reports.every((t) => !t.live && t.durationMs == 339000), isTrue);
    expect(progressAt(reports[0]).fraction, 33560 / 339000);
  });

  test('a position already in ms (after an OCP seek) is kept: it would overshoot as seconds', () {
    expect(trackModel({...song, 'position': 120000}).positionMs, 120000);
    expect(trackModel({...song, 'position': 120}).positionMs, 120000);
  });

  test('measured live stream: duration 0, length grows with position; the ring stays full', () {
    final stream = {
      'uri': 'https://ice1.somafm.com/groovesalad-128-mp3',
      'title': 'Groove Salad',
      'status': 'Playing',
      'duration': 0,
    };
    const samples = [(14, 43284), (16, 45270), (18, 47333), (20, 49554)];
    Track? previous;
    final models = [
      for (final (p, l) in samples) previous = trackModel({...stream, 'position': p, 'length': l}, previous),
    ];
    expect(models.every((t) => t.live && t.durationMs == 0), isTrue);
    expect(models.map((t) => t.positionMs), [14000, 16000, 18000, 20000]);
    expect(models.map((t) => progressAt(t, 1500).fraction), [1, 1, 1, 1]);
    expect(progressAt(models[3], 1500).elapsed, '0:21');
  });

  test('no declared duration: mpv\'s steady length becomes the total once it has held, through a pause', () {
    // The yt-dlp path: the media entry carries no length, so OCP sends duration 0, while mpv reports the real total.
    const stream = {'uri': 'https://www.youtube.com/watch?v=x', 'title': 'Big Buck Bunny', 'duration': 0, 'status': 'Playing'};
    final first = trackModel({...stream, 'position': 2.0, 'length': 634000.0});
    expect(first.live, isTrue, reason: 'one report cannot tell a finite stream from a live buffer');
    final second = trackModel({...stream, 'position': 4.0, 'length': 634000.0}, first);
    expect(second.live, isFalse);
    expect(second.durationMs, 634000);
    expect(progressAt(second).total, '10:34');
    final paused = trackModel({...stream, 'status': 'Paused', 'position': 4.0, 'length': 634000.0}, second);
    expect(paused.live, isFalse, reason: 'a pause keeps the total');
    final resumed = trackModel({...stream, 'position': 6.1, 'length': 634000.0}, paused);
    expect(resumed.durationMs, 634000);
    expect(trackModel({...stream, 'position': 4.0, 'length': 636000.0}, first).live, isTrue, reason: 'a growing buffer');
  });

  test('a claimed duration with a buffer length that grows in step with position still reads as live', () {
    final claimed = {...song, 'duration': 600000};
    final first = trackModel({...claimed, 'position': 14, 'length': 43284});
    final second = trackModel({...claimed, 'position': 16, 'length': 45270}, first);
    expect(first.live, isFalse);
    expect(second.live, isTrue);
    expect(trackModel({...claimed, 'position': 16, 'length': 43284}, first).live, isFalse);
  });

  test('progress advances only while playing and stops at the end', () {
    final playing = trackModel(song);
    expect(progressAt(playing, 50000).fraction, 0.25);
    expect(progressAt(playing, 999999).positionMs, 200000);
    expect(progressAt(trackModel({...song, 'status': 'Paused'}), 50000).positionMs, 0);
    final live = progressAt(trackModel({...song, 'duration': 0}), 42000);
    expect((live.fraction, live.elapsed, live.total), (1.0, '0:42', 'live'));
  });

  test('unrelated updates keep the clock running; pause freezes it; resume continues from there', () {
    var anchor = anchorFor(null, trackModel(song), 0);
    anchor = anchorFor(anchor, trackModel({...song, 'app_view_timeout': 30}), 10000);
    expect(anchor.positionMs, 10000);
    anchor = anchorFor(anchor, trackModel({...song, 'status': 'Paused'}), 16000);
    expect(anchor.positionMs, 16000);
    anchor = anchorFor(anchor, trackModel({...song, 'status': 'Playing'}), 30000);
    expect(anchor.positionMs, 16000);
    expect(progressAt(trackModel(song).withPosition(anchor.positionMs), 4000).positionMs, 20000);
  });

  test("a new track that inherits the old track's position starts at 0", () {
    final playing = anchorFor(null, trackModel({...song, 'position': 42.96}), 0);
    final next = anchorFor(playing, trackModel({...song, 'title': 'Next', 'position': 42.96}), 1000);
    expect(next.positionMs, 0);
    final reported = anchorFor(next, trackModel({...song, 'title': 'Next', 'position': 1.84}), 3000);
    expect(reported.positionMs, 1840);
  });

  test('a new track, a stop or a reported position restarts the clock', () {
    final running = anchorFor(anchorFor(null, trackModel(song), 0), trackModel(song), 14000);
    expect(running.positionMs, 14000);
    expect(anchorFor(running, trackModel({...song, 'title': 'Next'}), 15000).positionMs, 0);
    expect(anchorFor(running, trackModel({...song, 'status': 'Stopped'}), 15000).positionMs, 0);
    expect(anchorFor(running, trackModel({...song, 'position': 90000}), 15000).positionMs, 90000);
  });

  test('a paused record eases to the nearest upright, never more than half a turn', () {
    expect([0, 30, 179, 180, 300, -62, -170, -10, 540].map(uprightTarget), [0, 0, 0, 360, 360, 360, 360, 360, 360]);
  });

  test('status parts', () {
    final track = trackModel({...song, 'canNext': true, 'loopStatus': 'Repeat'});
    final parts = statusParts(track, progressAt(track, 5000));
    expect(parts.time, '0:05 / 3:20');
    expect(parts.flags, ['⏭', 'repeat']);
    expect(parts.live, isFalse);
    final Json empty = {};
    expect(statusParts(trackModel(empty), progressAt(trackModel(empty))).time, '0:00');
  });
}
