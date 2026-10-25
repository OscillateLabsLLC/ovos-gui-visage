/// Template page names: the OVOS-GUI-1 vocabulary (gui-1.md 3) is canonical, and the names producers send today are
/// aliases of it. The router keys its template pages by canonical name only; no alias appears anywhere else.
library;

/// Every GUI-1 template name starts with this.
const systemPrefix = 'SYSTEM_';

/// The closed GUI-1 template set (gui-1.md 3.4).
const specTemplates = {
  'SYSTEM_idle',
  'SYSTEM_loading',
  'SYSTEM_status',
  'SYSTEM_error',
  'SYSTEM_text',
  'SYSTEM_image',
  'SYSTEM_animated_image',
  'SYSTEM_list',
  'SYSTEM_grid',
  'SYSTEM_table',
  'SYSTEM_html',
  'SYSTEM_url',
  'SYSTEM_audio_player',
  'SYSTEM_video_player',
  'SYSTEM_media_player',
  'SYSTEM_clock',
  'SYSTEM_timer',
  'SYSTEM_weather',
  'SYSTEM_map',
  'SYSTEM_face',
};

/// Reserved by GUI-1 and never emitted by a producer, so they route as unknown pages, as do their QML files.
const reservedTemplates = {'SYSTEM_confirm', 'SYSTEM_select'};

/// Not part of GUI-1: reachable under its legacy name only.
const legacyOnlyTemplates = {'SYSTEM_InputBox'};

/// ovos-bus-client's frame names (ovos-gui #117, `LEGACY_TO_SPEC`).
const _busClientNames = {
  'SYSTEM_TextFrame': 'SYSTEM_text',
  'SYSTEM_ImageFrame': 'SYSTEM_image',
  'SYSTEM_AnimatedImageFrame': 'SYSTEM_animated_image',
  'SYSTEM_HtmlFrame': 'SYSTEM_html',
  'SYSTEM_UrlFrame': 'SYSTEM_url',
  'SYSTEM_Status': 'SYSTEM_status',
  'SYSTEM_Loading': 'SYSTEM_loading',
  'SYSTEM_Face': 'SYSTEM_face',
};

/// The QML files ovos-legacy-mycroft-gui-plugin shows for each spec template (`_TEMPLATE_QML`).
const _legacyPluginQml = {
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

/// Every legacy name, mapped to the spec template it shows.
const templateAliases = {..._busClientNames, ..._legacyPluginQml};

/// The canonical name of a template page, or null when [page] names no template.
String? canonicalTemplate(String page) {
  if (specTemplates.contains(page) || legacyOnlyTemplates.contains(page)) return page;
  return templateAliases[page];
}
