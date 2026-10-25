import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/attention.dart';
import 'package:ovos_gui_visage/pages/clock_page.dart';
import 'package:ovos_gui_visage/pages/confirm_page.dart';
import 'package:ovos_gui_visage/pages/error_page.dart';
import 'package:ovos_gui_visage/pages/fallback_page.dart';
import 'package:ovos_gui_visage/pages/grid_page.dart';
import 'package:ovos_gui_visage/pages/html_frame_page.dart';
import 'package:ovos_gui_visage/pages/image_frame_page.dart';
import 'package:ovos_gui_visage/pages/input_box_page.dart';
import 'package:ovos_gui_visage/pages/list_page.dart';
import 'package:ovos_gui_visage/pages/loading_page.dart';
import 'package:ovos_gui_visage/pages/map_page.dart';
import 'package:ovos_gui_visage/pages/media_pages.dart';
import 'package:ovos_gui_visage/pages/page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/pages/select_page.dart';
import 'package:ovos_gui_visage/pages/status_page.dart';
import 'package:ovos_gui_visage/pages/system_face_page.dart';
import 'package:ovos_gui_visage/pages/system_timer_page.dart';
import 'package:ovos_gui_visage/pages/system_weather_page.dart';
import 'package:ovos_gui_visage/pages/table_page.dart';
import 'package:ovos_gui_visage/pages/template_names.dart';
import 'package:ovos_gui_visage/pages/text_frame_page.dart';
import 'package:ovos_gui_visage/pages/url_frame_page.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui_state_test.dart' show loadFixture;

/// Written from ovos-gui #117 `LEGACY_TO_SPEC` and the legacy plugin's `_TEMPLATE_QML`, not from lib/, so a changed
/// alias fails here.
const expectedAliases = {
  'SYSTEM_TextFrame': 'SYSTEM_text',
  'SYSTEM_ImageFrame': 'SYSTEM_image',
  'SYSTEM_AnimatedImageFrame': 'SYSTEM_animated_image',
  'SYSTEM_HtmlFrame': 'SYSTEM_html',
  'SYSTEM_UrlFrame': 'SYSTEM_url',
  'SYSTEM_Status': 'SYSTEM_status',
  'SYSTEM_Loading': 'SYSTEM_loading',
  'SYSTEM_Face': 'SYSTEM_face',
  'Idle.qml': 'SYSTEM_idle',
  'Loading.qml': 'SYSTEM_loading',
  'Status.qml': 'SYSTEM_status',
  'Error.qml': 'SYSTEM_error',
  'Text.qml': 'SYSTEM_text',
  'Image.qml': 'SYSTEM_image',
  'AnimatedImage.qml': 'SYSTEM_animated_image',
  'List.qml': 'SYSTEM_list',
  'Grid.qml': 'SYSTEM_grid',
  'Table.qml': 'SYSTEM_table',
  'Html.qml': 'SYSTEM_html',
  'Url.qml': 'SYSTEM_url',
  'AudioPlayer.qml': 'SYSTEM_audio_player',
  'VideoPlayer.qml': 'SYSTEM_video_player',
  'MediaPlayer.qml': 'SYSTEM_media_player',
  'Clock.qml': 'SYSTEM_clock',
  'Timer.qml': 'SYSTEM_timer',
  'Weather.qml': 'SYSTEM_weather',
  'Map.qml': 'SYSTEM_map',
  'Face.qml': 'SYSTEM_face',
};

const implemented = <String, PageBuilder>{
  'SYSTEM_text': TextFramePage.page,
  'SYSTEM_image': ImageFramePage.page,
  'SYSTEM_animated_image': ImageFramePage.page,
  'SYSTEM_html': HtmlFramePage.page,
  'SYSTEM_url': UrlFramePage.page,
  'SYSTEM_status': StatusPage.page,
  'SYSTEM_loading': LoadingPage.page,
  'SYSTEM_face': SystemFacePage.page,
  'SYSTEM_error': ErrorPage.page,
  'SYSTEM_list': ListPage.page,
  'SYSTEM_grid': GridPage.page,
  'SYSTEM_table': TablePage.page,
  'SYSTEM_audio_player': AudioPlayerPage.page,
  'SYSTEM_video_player': VideoPlayerPage.page,
  'SYSTEM_media_player': MediaPlayerPage.page,
  'SYSTEM_clock': ClockPage.page,
  'SYSTEM_timer': SystemTimerPage.page,
  'SYSTEM_weather': SystemWeatherPage.page,
  'SYSTEM_map': MapPage.page,
};

const unimplemented = {'SYSTEM_idle'};

const unknown = ['Confirm.qml', 'Select.qml', 'SYSTEM_ocp_now_playing', 'Mystery'];

/// The drafted amendment A companions, real templates since then.
const companions = <String, PageBuilder>{
  'SYSTEM_confirm': ConfirmPage.page,
  'SYSTEM_select': SelectPage.page,
  'SYSTEM_input': InputBoxPage.companion,
};

PageBuilder route(String page, [TemplateGaps? gaps]) => resolve(Target('any.skill', page, 0), gaps: gaps ?? TemplateGaps());

void main() {
  test('the spec vocabulary is the 20 GUI-1 templates, split into implemented and not yet', () {
    expect(specTemplates, {...implemented.keys, ...unimplemented});
    expect(specTemplates, hasLength(20));
    expect(specTemplates.intersection(companionTemplates), isEmpty);
  });

  test('the three companions of amendment A are their own canonical names and reach their pages', () {
    expect(companionTemplates, companions.keys.toSet());
    for (final MapEntry(key: name, value: page) in companions.entries) {
      expect(canonicalTemplate(name), name);
      expect(route(name), same(page), reason: name);
    }
  });

  test('every alias maps to its spec template', () {
    expect(templateAliases, expectedAliases);
    for (final MapEntry(key: alias, value: spec) in expectedAliases.entries) {
      expect(canonicalTemplate(alias), spec, reason: alias);
    }
  });

  test('every spec name is its own canonical name; SYSTEM_InputBox is legacy only', () {
    for (final spec in specTemplates) {
      expect(canonicalTemplate(spec), spec);
    }
    expect(canonicalTemplate('SYSTEM_InputBox'), 'SYSTEM_InputBox');
    expect(canonicalTemplate('SYSTEM_input_box'), isNull);
  });

  test('every implemented template is reached by its spec name and every alias', () {
    for (final MapEntry(key: spec, value: page) in implemented.entries) {
      final names = [
        spec,
        for (final e in expectedAliases.entries)
          if (e.value == spec) e.key,
      ];
      for (final name in names) {
        expect(route(name), same(page), reason: name);
      }
    }
    expect(route('SYSTEM_InputBox'), same(InputBoxPage.page));
  });

  test('SYSTEM_TextFrame, SYSTEM_text and Text.qml reach the same page', () {
    expect({route('SYSTEM_TextFrame'), route('SYSTEM_text'), route('Text.qml')}, {TextFramePage.page});
  });

  test('reserved, non-spec and unknown names show the fallback without a fault', () async {
    final faults = await collectFaults(() async {
      for (final name in unknown) {
        expect(route(name), same(FallbackPage.page), reason: name);
      }
    });
    expect(faults, isEmpty);
  });

  for (final spec in unimplemented) {
    test('$spec shows the fallback and is reported once, under any of its names', () async {
      final gaps = TemplateGaps();
      final names = [
        spec,
        for (final e in expectedAliases.entries)
          if (e.value == spec) e.key,
      ];
      final faults = await collectFaults(() async {
        for (final name in [...names, ...names]) {
          expect(route(name, gaps), same(FallbackPage.page), reason: name);
        }
      });
      expect(faults.map((f) => '${f.exception}'), ['UnimplementedError: $spec has no page yet']);
    });
  }

  test('the face template by any name keeps the full face', () {
    for (final name in ['SYSTEM_face', 'SYSTEM_Face', 'Face.qml']) {
      expect(isContentPage(Target('any.skill', name, 0), defaultIdleNamespace), isFalse, reason: name);
    }
    expect(isContentPage(const Target('any.skill', 'SYSTEM_text', 0), defaultIdleNamespace), isTrue);
  });

  test('templates_show_all replays onto real pages, with no fault', () async {
    final pages = <String>{};
    final faults = await collectFaults(() async {
      final state = GuiState();
      for (final message in loadFixture(File('test/fixtures/templates_show_all.jsonl'))) {
        state.apply(message);
        final target = state.current();
        if (target == null) continue;
        pages.add(target.page);
        expect(resolve(target, gaps: TemplateGaps()), isNot(same(FallbackPage.page)), reason: '$target');
      }
    });
    expect(faults, isEmpty, reason: faults.map((f) => f.exceptionAsString()).join('\n'));
    expect(pages, containsAll(['SYSTEM_TextFrame', 'SYSTEM_Status', 'SYSTEM_InputBox', 'SYSTEM_AnimatedImageFrame']));
  });
}
