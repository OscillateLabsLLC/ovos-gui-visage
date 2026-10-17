/// View model for the OCP now-playing page (SPEC 8.6), port of ocp_model.js. Pure.
///
/// Units, measured: `duration` is the track's own length in ms (0 for a live stream). `position` is mpv `time-pos`
/// in seconds, about every 2 s, except after an OCP seek, which writes ms. `length` is mpv duration in ms, which on
/// a live stream is the growing buffer, so it is never used as the total.
library;

import 'dart:math' as math;

import '../json.dart';
import 'page.dart';

const syncPlayer = 'OVOSSyncPlayer';

enum PlaybackState { playing, paused, stopped }

PlaybackState playbackState(Object? status) => switch (text(status).toLowerCase()) {
      'playing' => PlaybackState.playing,
      'paused' => PlaybackState.paused,
      _ => PlaybackState.stopped,
    };

final _loadable = RegExp(r'^(data:|https?://|/)');
const _overshoot = 1.05;
// Two reports ~2 s apart on a live stream: length and position each grow by ~2000 ms; allow mpv's jitter.
const _trackingSlackMs = 1500;

/// Cover art the display can try to load: data:, http(s), the middle layer's /res/ URLs, and (same-host) paths.
String? coverUrl(Object? image) {
  final url = text(image);
  return _loadable.hasMatch(url) ? url : null;
}

String _pad2(int n) => n.toString().padLeft(2, '0');

String formatTime(num ms) {
  final total = math.max(0, (ms / 1000).floor());
  final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
  return h > 0 ? '$h:${_pad2(m)}:${_pad2(s)}' : '$m:${_pad2(s)}';
}

/// Position in ms: seconds unless reading it as seconds would put it past the end of a finite track.
double positionMs(Object? position, double totalMs) {
  final value = number(position);
  if (!(value > 0)) return 0;
  return totalMs > 0 && value * 1000 > totalMs * _overshoot ? value : value * 1000;
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.cover,
    required this.state,
    required this.durationMs,
    required this.lengthMs,
    required this.positionMs,
    required this.live,
    required this.canPrev,
    required this.canNext,
    required this.repeat,
    required this.shuffle,
  });

  final String id, title, artist;
  final String? cover;
  final PlaybackState state;
  final double durationMs, lengthMs, positionMs;
  final bool live, canPrev, canNext, repeat, shuffle;

  Track withPosition(double ms, {PlaybackState? state}) => Track(
        id: id, title: title, artist: artist, cover: cover, state: state ?? this.state, durationMs: durationMs,
        lengthMs: lengthMs, positionMs: ms, live: live, canPrev: canPrev, canNext: canNext, repeat: repeat, shuffle: shuffle,
      );
}

/// The buffer `length` growing in step with `position` marks a live stream even when a duration is claimed.
bool _lengthTracksPosition(Track? previous, double lengthMs, double position) {
  if (previous == null || !(previous.lengthMs > 0) || !(lengthMs > previous.lengthMs) || !(position > previous.positionMs)) {
    return false;
  }
  return (lengthMs - previous.lengthMs - (position - previous.positionMs)).abs() < _trackingSlackMs;
}

/// Everything the page shows except the clock-driven position, which [progressAt] adds. [previous] is the last model.
Track trackModel(Json data, [Track? previous]) {
  final duration = math.max(0.0, number(data['duration']));
  final lengthMs = math.max(0.0, number(data['length']));
  final position = positionMs(data['position'], duration);
  final id = [text(data['uri']), text(data['title']), duration].join('|');
  final live = duration == 0 || _lengthTracksPosition(previous?.id == id ? previous : null, lengthMs, position);
  final title = text(data['title']);
  return Track(
    id: id,
    title: title.isEmpty ? 'Unknown track' : title,
    artist: text(data['artist']),
    cover: coverUrl(data['image']),
    state: playbackState(data['status']),
    durationMs: live ? 0 : duration,
    lengthMs: lengthMs,
    positionMs: position,
    live: live,
    canPrev: truthy(data['canPrev']),
    canNext: truthy(data['canNext']),
    repeat: data['loopStatus'] == 'Repeat' || data['loopStatus'] == 'RepeatTrack',
    shuffle: data['shuffleStatus'] == true,
  );
}

typedef Progress = ({double positionMs, double fraction, String elapsed, String total});

/// Position [sinceUpdateMs] after the last update: it advances only while playing and stops at the end.
Progress progressAt(Track track, [double sinceUpdateMs = 0]) {
  final advance = track.state == PlaybackState.playing ? math.max(0.0, sinceUpdateMs) : 0.0;
  final position = track.live ? track.positionMs + advance : math.min(track.durationMs, track.positionMs + advance);
  return (
    positionMs: position,
    fraction: track.live ? 1 : (track.durationMs > 0 ? position / track.durationMs : 0),
    elapsed: formatTime(position),
    total: track.live ? 'live' : formatTime(track.durationMs),
  );
}

/// Where the position clock stands: the estimated position, what OCP last reported, and when.
typedef Anchor = ({String id, double positionMs, double reportedMs, PlaybackState state, double at});

bool _restarts(Anchor? previous, Track track) =>
    previous == null || track.id != previous.id || track.state == PlaybackState.stopped || track.positionMs != previous.reportedMs;

/// A new track, a stop or a new reported position restarts the clock at the reported position; any other update
/// (pause, resume, unrelated keys) carries the running estimate forward, so pausing freezes it in place.
Anchor anchorFor(Anchor? previous, Track track, double nowMs) {
  if (_restarts(previous, track)) {
    // OCP leaves the old track's position in place when the track changes; until mpv reports, the new one starts at 0.
    final stale = previous != null && track.id != previous.id && track.positionMs == previous.reportedMs;
    return (id: track.id, positionMs: stale ? 0 : track.positionMs, reportedMs: track.positionMs, state: track.state, at: nowMs);
  }
  final running = progressAt(track.withPosition(previous!.positionMs, state: previous.state), nowMs - previous.at);
  return (id: track.id, positionMs: running.positionMs, reportedMs: previous.reportedMs, state: track.state, at: nowMs);
}

typedef StatusParts = ({PlaybackState state, String time, bool live, List<String> flags});

/// The pieces of the status line: state word, time text, whether to show the live dot, and the capability flags.
StatusParts statusParts(Track track, Progress progress) => (
      state: track.state,
      time: track.live ? progress.elapsed : '${progress.elapsed} / ${progress.total}',
      live: track.live,
      flags: [if (track.canPrev) '⏮', if (track.canNext) '⏭', if (track.repeat) 'repeat', if (track.shuffle) 'shuffle'],
    );

/// The upright angle a paused record eases to from [degrees]: back to 0 in the first half turn, on to 360 in the second.
double uprightTarget(num degrees) {
  final angle = ((degrees % 360) + 360) % 360;
  return angle < 180 ? 0 : 360;
}

bool isSyncPlayer(Json data) => (data['playerBackend'] ?? syncPlayer) == syncPlayer;
