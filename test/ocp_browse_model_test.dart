// Port of tests/js/ocp_browse_model.test.mjs.
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/ocp_browse_model.dart';

const yt = 'ovos-skill-youtube-music.openvoiceos';

Map<String, dynamic> card(String track, int duration, String uri) => {
  'track': track,
  'album': yt,
  'duration': duration,
  'image': '',
  'source': '/venv/ovos_skill_youtube_music/ui/icon.png',
  'uri': uri,
};

final playlist = [
  card('Moonlight Sonata (Flute & Piano)', 339000, 'yt://1'),
  card('Moonlight Sonata (Orchestra Version)', 339000, 'yt://2'),
  card('Moonlight Sonata (Marimba Version)', 284000, 'yt://3'),
];

void main() {
  test('skill ids read as plain names', () {
    expect(skillName(yt), 'youtube music');
    expect(skillName('skill-ovos-somafm.openvoiceos'), 'somafm');
    expect(skillName('skill-easter-eggs.openvoiceos'), 'easter eggs');
    expect(skillName(null), '');
  });

  test("busy shows OCP's footer text, else the stock label", () {
    expect(busyLabel({'footer_text': 'Searching...'}), 'Searching...');
    expect(busyLabel({}), 'Searching media');
  });

  test('suggestions: the playlist with source and length beneath, the playing entry marked', () {
    final model = suggestionsModel({
      'playlistModel': {'data': playlist},
      'searchModel': {'data': []},
      'uri': 'yt://2',
    });
    expect(model.heading, 'Playlist');
    expect(model.rows.map((r) => r.current), [false, true, false]);
    expect(model.rows[2].subtitle, 'youtube music · 4:44');
    // Same-host display: the skill icon path is a loadable candidate.
    expect(model.rows[0].cover, '/venv/ovos_skill_youtube_music/ui/icon.png');
  });

  test('suggestions fall back to search results when there is no playlist', () {
    final model = suggestionsModel({
      'playlistModel': {'data': []},
      'searchModel': {'data': playlist.sublist(0, 1)},
    });
    expect(model.heading, 'Search results');
    expect(model.rows.length, 1);
    expect(suggestionsModel({}).rows, isEmpty);
  });

  test('long lists keep the playing row in view and count the rest', () {
    final all = [for (var i = 0; i < 20; i++) BrowseRow(title: 't$i', subtitle: '', cover: null, current: i == 15)];
    final (:rows, :hidden) = windowRows(all);
    expect(rows.length, maxRows);
    expect(hidden, 20 - maxRows);
    expect(rows.any((r) => r.current), isTrue);
    expect(windowRows(all.sublist(0, 3)).hidden, 0);
  });

  test('home lists featured OCP skills with their media types, else the playlist as recent entries', () {
    final cards = [
      {
        'skill_id': 'ovos-skill-news.openvoiceos',
        'title': 'News Skill',
        'image': '/venv/news.png',
        'media_type': [8, 0],
      },
      {
        'skill_id': 'skill-ovos-somafm.openvoiceos',
        'title': 'somafm skill',
        'image': '/venv/somafm.png',
        'media_type': [2, 7, 0],
      },
    ];
    final skills = homeModel({'skillCards': cards});
    expect(skills.heading, 'Media');
    expect(skills.layout, BrowseLayout.chips);
    expect(skills.rows.map((r) => [r.title, r.subtitle]), [
      ['News Skill', 'news'],
      ['somafm skill', 'music · radio'],
    ]);
    expect(mediaTypes(7), 'radio');
    final recent = homeModel({
      'skillCards': [],
      'playlistModel': {'data': playlist},
    });
    expect((recent.heading, recent.rows.length, recent.layout), ('Recent', 3, BrowseLayout.rows));
  });

  test('home chips carry the skill icon and a hue that is stable per skill', () {
    final somafm = {
      'skill_id': 'skill-ovos-somafm.openvoiceos',
      'title': 'somafm skill',
      'image': '/res-abs/aaaa',
      'media_type': [2, 7],
    };
    final home = homeModel({
      'skillCards': [
        somafm,
        {...somafm, 'skill_id': 'ovos-skill-news.openvoiceos', 'title': 'News'},
      ],
    });
    expect(home.rows[0].cover, '/res-abs/aaaa');
    expect(skillHue(somafm['skill_id']), skillHue(somafm['skill_id']));
    expect(home.rows[0].hue, isNot(home.rows[1].hue));
    expect(home.rows.every((row) => row.hue! >= 0 && row.hue! < 360), isTrue);
  });

  test('suggestions fill up with search results after the playlist, labelled, without repeating an entry', () {
    final results = [playlist[1], card('Drone Zone', 0, 'yt://9'), card('Groove Salad', 0, 'yt://10')];
    final model = suggestionsModel({
      'playlistModel': {
        'data': [playlist[1]],
      },
      'searchModel': {'data': results},
      'uri': 'yt://2',
    });
    expect(model.heading, 'Playlist');
    expect(model.rows.map((r) => [r.title, r.section, r.current]), [
      ['Moonlight Sonata (Orchestra Version)', null, true],
      ['Drone Zone', 'Search results', false],
      ['Groove Salad', null, false],
    ]);
  });
}
