/// SYSTEM_media_player's views (gui-1.md §3.4, line 241): which ones its data can fill, and the queue and search
/// results as the OCP list page's [BrowseModel]. Rows cannot be tapped: OCP's `playlist.play` takes its own entry
/// shape, and GUI-1 leaves the media-control surface out of scope (§7.1, finding F21).
library;

import '../json.dart';
import 'media_keys.dart';
import 'media_model.dart';
import 'ocp_browse_model.dart';
import 'ocp_model.dart';
import 'page.dart';

enum MediaView { loading, error, nowPlaying, results, queue, empty }

/// The chips that switch views. At most one of loading, error and now-playing is present, so they share a label.
const viewLabels = {
  MediaView.loading: 'Now playing',
  MediaView.error: 'Now playing',
  MediaView.nowPlaying: 'Now playing',
  MediaView.results: 'Results',
  MediaView.queue: 'Queue',
};

MediaKeys mediaKeys(Json data) => MediaKeys(mediaPlayer, data, prefix: 'media_');

bool _hasTrack(MediaKeys keys) => (keys.string('title') ?? '').isNotEmpty || (keys.string('uri') ?? '').isNotEmpty;

/// The views the data can fill, the one to show first leading: loading or error while the state says so, then the
/// current track, the search results, the queue; [MediaView.empty] when there is nothing (finding F20).
List<MediaView> mediaViews(Json data) {
  final keys = mediaKeys(data);
  final state = mediaState(keys);
  final views = [
    if (state == MediaState.loading) MediaView.loading,
    if (state == MediaState.error) MediaView.error,
    if (_hasTrack(keys) && state != MediaState.loading && state != MediaState.error) MediaView.nowPlaying,
    if (keys.items('search_results').isNotEmpty) MediaView.results,
    if (keys.items('playlist').isNotEmpty) MediaView.queue,
  ];
  return views.isEmpty ? const [MediaView.empty] : views;
}

/// What the busy and error views say: the title when there is one.
String mediaStateLabel(Json data, MediaView view) {
  final title = mediaKeys(data).string('title') ?? '';
  return switch (view) {
    MediaView.loading => title.isEmpty ? 'Loading media' : 'Loading $title',
    MediaView.error => title.isEmpty ? 'Could not play the media' : 'Could not play $title',
    _ => title,
  };
}

/// Entries carry `duration` in ms like the player's own (finding F19); it shows only when positive.
BrowseRow _itemRow(MediaKeys keys, String list, Map item, {required bool current, Object? skillId}) {
  final duration = number(item['duration']);
  final title = text(item['title']);
  return BrowseRow(
    title: title.isEmpty ? 'Untitled' : title,
    subtitle: [
      text(item['artist']),
      skillName(skillId),
      if (duration > 0) formatTime(duration),
    ].where((s) => s.isNotEmpty).join(' · '),
    cover: coverOf(keys, list, item['image']),
    current: current,
  );
}

final _wireImage = RegExp(r'^(data:|https?://)', caseSensitive: false);

/// §3.5 for list entries: http(s) and data: only; anything else is reported against [list] and dropped.
String? coverOf(MediaKeys keys, String list, Object? image) {
  final url = text(image);
  if (url.isEmpty) return null;
  if (_wireImage.hasMatch(url)) return url;
  keys.fault(list, 'entry image must be an http(s) URL or a data: URI (§3.5)', image);
  return null;
}

/// The queue, the entry at `media_playlist_position` (else the one whose uri is `media_uri`) marked as playing.
BrowseModel queueModel(Json data) {
  final keys = mediaKeys(data);
  final queue = keys.items('playlist');
  final index = playlistIndex(keys, queue.length);
  final uri = keys.string('uri') ?? '';
  bool current(int i) => index != null ? i == index : uri.isNotEmpty && queue[i]['uri'] == uri;
  final rows = [for (final (i, item) in queue.indexed) _itemRow(keys, 'playlist', item, current: current(i))];
  final window = windowRows(rows);
  return (heading: 'Queue', layout: BrowseLayout.rows, rows: window.rows, hidden: window.hidden);
}

/// Search results with the skill that found each; `match_confidence` is not shown (its range is unspecified, F19).
BrowseModel resultsModel(Json data) {
  final keys = mediaKeys(data);
  final uri = keys.string('uri') ?? '';
  final rows = [
    for (final item in keys.items('search_results'))
      _itemRow(keys, 'search_results', item, current: uri.isNotEmpty && item['uri'] == uri, skillId: item['skill_id']),
  ];
  final window = windowRows(rows);
  return (heading: 'Search results', layout: BrowseLayout.rows, rows: window.rows, hidden: window.hidden);
}
