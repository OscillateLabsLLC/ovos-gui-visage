/// View models for the GUI-1 media templates ([gui-1.md 3.4 Catalogue](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#34-catalogue)),
/// onto the OCP pages' own models: a [Track] for the now-playing view and a [BrowseModel] for the queue and the search
/// results. Positions and durations are milliseconds, `-1` is unknown or live; legacy OCP's seconds heuristic
/// ([positionMs]) is never applied here.
library;

import '../json.dart';
import 'media_keys.dart';
import 'ocp_browse_model.dart';
import 'ocp_model.dart';

const audioPlayer = 'SYSTEM_audio_player';
const videoPlayer = 'SYSTEM_video_player';
const mediaPlayer = 'SYSTEM_media_player';

/// Where the transport goes whichever namespace showed the template: 7.1 points controls at the media subsystem, and
/// OCP's `ovos.common_play.*` messages are the only media-control surface OVOS has (finding F21).
const ocpNamespace = 'ovos.common_play';

const unknownOrLive = -1.0;

/// `-1` and an omitted duration are both unknown or live (finding F18); any other value that is not positive is
/// reported (0 is legacy OCP's live marker) and read the same way.
double? _durationMs(MediaKeys keys) {
  final value = keys.number('duration');
  if (value == null || value == unknownOrLive) return null;
  if (value > 0) return value;
  keys.fault('duration', 'must be positive ms or -1 (unknown/live)', value);
  return null;
}

/// `-1` is unknown here too: the convention covers the pair (finding F18). Any other negative value is reported.
double _positionMs(MediaKeys keys) {
  final value = keys.number('position') ?? 0;
  if (value >= 0) return value;
  if (value == unknownOrLive) return 0;
  keys.fault('position', 'must not be negative', value);
  return 0;
}

/// A track from the keys the two players share: title, artist, album, image, position, duration.
Track gui1Track(MediaKeys keys, PlaybackState state, {bool required = false, bool canPrev = false, bool canNext = false}) {
  final title = keys.string('title', required: required) ?? '';
  final byline = [keys.string('artist'), keys.string('album')].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  final duration = _durationMs(keys);
  return Track(
    id: [keys.string('uri') ?? '', title, byline, duration ?? unknownOrLive].join('|'),
    title: title.isEmpty ? 'Unknown track' : title,
    artist: byline,
    cover: keys.image('image'),
    state: state,
    durationMs: duration ?? 0,
    lengthMs: duration ?? 0,
    positionMs: _positionMs(keys),
    live: duration == null,
    canPrev: canPrev,
    canNext: canNext,
    repeat: false,
    shuffle: false,
  );
}

/// `playing` true plays, false pauses; omitted, nothing is claimed to move, so it reads as paused.
PlaybackState playingState(MediaKeys keys) => (keys.flag('playing') ?? false) ? PlaybackState.playing : PlaybackState.paused;

/// SYSTEM_audio_player: `title` is required.
Track audioTrack(Json data, [Track? previous]) {
  final keys = MediaKeys(audioPlayer, data);
  return gui1Track(keys, playingState(keys), required: true);
}

typedef VideoModel = ({String title, PlaybackState state});

/// SYSTEM_video_player, degraded to its title and play state: `uri` is required but not shown; with
/// no title the last part of the uri names it.
VideoModel videoModel(Json data) {
  final keys = MediaKeys(videoPlayer, data);
  final uri = keys.string('uri', required: true) ?? '';
  final title = keys.string('title') ?? '';
  final segments = Uri.tryParse(uri)?.pathSegments.where((s) => s.isNotEmpty) ?? const <String>[];
  final named = title.isNotEmpty ? title : (segments.isEmpty ? 'Video' : Uri.decodeComponent(segments.last));
  return (title: named, state: playingState(keys));
}

/// `media_playback_state`. `loading` and `error` choose their own view, so they are not a [PlaybackState].
enum MediaState { playing, paused, stopped, loading, error }

/// Omitted reads as paused, as for the audio player; another value, a capitalised OCP status included, is reported.
MediaState mediaState(MediaKeys keys) {
  final value = keys.string('playback_state');
  if (value == null) return MediaState.paused;
  for (final state in MediaState.values) {
    if (state.name == value) return state;
  }
  keys.fault('playback_state', 'must be playing, paused, stopped, loading or error', value);
  return MediaState.values.asNameMap()[value.toLowerCase()] ?? MediaState.paused;
}

PlaybackState _playback(MediaState state) => switch (state) {
  MediaState.playing => PlaybackState.playing,
  MediaState.stopped => PlaybackState.stopped,
  _ => PlaybackState.paused,
};

/// `media_playlist_position`, read as a 0-based index into `media_playlist` (finding F19); out of range is reported.
int? playlistIndex(MediaKeys keys, int length) {
  final value = keys.number('playlist_position');
  if (value == null) return null;
  if (value == value.roundToDouble() && value >= 0 && value < length) return value.toInt();
  keys.fault('playlist_position', 'must be a 0-based index into media_playlist', value);
  return null;
}

/// SYSTEM_media_player's now-playing view. Previous and next are offered where the queue has an entry before or after.
Track mediaTrack(Json data, [Track? previous]) {
  final keys = MediaKeys(mediaPlayer, data, prefix: 'media_');
  final queue = keys.items('playlist');
  final index = playlistIndex(keys, queue.length);
  return gui1Track(
    keys,
    _playback(mediaState(keys)),
    canPrev: index != null && index > 0,
    canNext: index != null && index < queue.length - 1,
  );
}
