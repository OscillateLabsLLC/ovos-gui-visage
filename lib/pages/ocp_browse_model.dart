/// View models for the OCP browse screens (SPEC 8.6): busy, SuggestionsView and Home. Port of ocp_browse_model.js.
///
/// List entries are MediaEntry.infocard dicts (ovos_utils/ocp.py): {track, album (the skill id), duration (ms),
/// image, source (skill icon path), uri}. There is no artist field, so the line under a title is the source skill
/// and length.
library;

import 'dart:math' as math;

import '../json.dart';
import 'ocp_model.dart';
import 'page.dart';

const searching = 'Searching media';
// ovos_utils.ocp.MediaType values a skill card can list; 0 (GENERIC) says nothing and is left out.
const mediaTypeNames = {
  1: 'audio', 2: 'music', 3: 'video', 4: 'audiobooks', 5: 'games', 6: 'podcasts', 7: 'radio', 8: 'news', 9: 'tv',
  10: 'movies', 11: 'trailers', 15: 'documentaries', 16: 'radio theatre', 17: 'short films', 19: 'series', 21: 'cartoons',
  22: 'anime', 23: 'asmr',
};
final _skillAffixes = [RegExp(r'\.openvoiceos$'), RegExp(r'\.[a-z0-9_-]+$'), RegExp(r'^ovos-skill-'), RegExp(r'^skill-ovos-'), RegExp(r'^skill-')];
const maxRows = 7;
// Home's skill chips: two columns of three fit above the attention strip.
const maxChips = 6;
const _hues = 360;

/// "ovos-skill-youtube-music.openvoiceos" -> "youtube music".
String skillName(Object? skillId) {
  var name = text(skillId);
  for (final affix in _skillAffixes) {
    name = name.replaceFirst(affix, '');
  }
  return name.replaceAll(RegExp(r'[-_]+'), ' ').trim();
}

String busyLabel(Json data) {
  final label = text(data['footer_text']);
  return label.isEmpty ? searching : label;
}

class BrowseRow {
  const BrowseRow({required this.title, required this.subtitle, required this.cover, required this.current, this.section, this.hue});

  final String title;
  final String subtitle;
  final String? cover;
  final bool current;
  final String? section;
  final int? hue;

  BrowseRow withSection(String section) =>
      BrowseRow(title: title, subtitle: subtitle, cover: cover, current: current, section: section, hue: hue);

  @override
  bool operator ==(Object other) =>
      other is BrowseRow && other.title == title && other.subtitle == subtitle && other.cover == cover && other.current == current && other.section == section && other.hue == hue;

  @override
  int get hashCode => Object.hash(title, subtitle, cover, current, section, hue);
}

BrowseRow _entryRow(Map entry, String currentUri) {
  final duration = number(entry['duration']);
  final length = duration > 0 ? formatTime(duration) : '';
  final title = text(entry['track']);
  return BrowseRow(
    title: title.isEmpty ? 'Untitled' : title,
    subtitle: [skillName(entry['album']), length].where((s) => s.isNotEmpty).join(' · '),
    cover: coverUrl(entry['image']) ?? coverUrl(entry['source']),
    current: currentUri.isNotEmpty && entry['uri'] == currentUri,
  );
}

/// At most [size] rows, keeping the current one in view; `hidden` counts what was left out.
({List<BrowseRow> rows, int hidden}) windowRows(List<BrowseRow> rows, [int size = maxRows]) {
  if (rows.length <= size) return (rows: rows, hidden: 0);
  final current = math.max(0, rows.indexWhere((row) => row.current));
  final start = math.min(math.max(0, current - size ~/ 2), rows.length - size);
  return (rows: rows.sublist(start, start + size), hidden: rows.length - size);
}

List<Map> _entries(Object? model) {
  final data = model is Map ? model['data'] : null;
  return data is List ? data.whereType<Map>().toList() : const [];
}

enum BrowseLayout { rows, chips }

typedef BrowseModel = ({String heading, BrowseLayout layout, List<BrowseRow> rows, int hidden});

/// The playlist first, then search results it does not already hold, the first of them labelled as a new section.
BrowseModel suggestionsModel(Json data) {
  final playlist = _entries(data['playlistModel']);
  final inPlaylist = {for (final entry in playlist) entry['uri']};
  final results = _entries(data['searchModel']).where((entry) => !inPlaylist.contains(entry['uri'])).toList();
  final uri = text(data['uri']);
  final rows = [for (final entry in [...playlist, ...results]) _entryRow(entry, uri)];
  if (playlist.isNotEmpty && results.isNotEmpty) rows[playlist.length] = rows[playlist.length].withSection('Search results');
  final window = windowRows(rows);
  return (heading: playlist.isNotEmpty ? 'Playlist' : 'Search results', layout: BrowseLayout.rows, rows: window.rows, hidden: window.hidden);
}

String mediaTypes(Object? types) {
  final list = types is List ? types : [types];
  final names = <String>{};
  for (final type in list) {
    final name = mediaTypeNames[number(type, -1).toInt()];
    if (name != null) names.add(name);
  }
  return names.join(' · ');
}

/// A stable hue per skill for its chip's gradient, so each skill keeps its colour between visits.
int skillHue(Object? skillId) {
  var hash = 0;
  for (final rune in text(skillId).runes) {
    hash = (hash * 31 + rune) & 0xFFFFFFFF;
  }
  return hash % _hues;
}

BrowseRow _skillRow(Map card) {
  final title = text(card['title']);
  return BrowseRow(
    title: title.isEmpty ? skillName(card['skill_id']) : title,
    subtitle: mediaTypes(card['media_type']),
    cover: coverUrl(card['image']),
    hue: skillHue(card['skill_id']),
    current: false,
  );
}

/// Featured OCP skills (skillCards, set when Home opens) when OCP lists any, else the current playlist as recent entries.
BrowseModel homeModel(Json data) {
  final raw = data['skillCards'];
  final cards = raw is List ? raw.whereType<Map>().toList() : const <Map>[];
  if (cards.isNotEmpty) {
    final window = windowRows([for (final card in cards) _skillRow(card)], maxChips);
    return (heading: 'Media', layout: BrowseLayout.chips, rows: window.rows, hidden: window.hidden);
  }
  final uri = text(data['uri']);
  final window = windowRows([for (final entry in _entries(data['playlistModel'])) _entryRow(entry, uri)]);
  return (heading: 'Recent', layout: BrowseLayout.rows, rows: window.rows, hidden: window.hidden);
}
