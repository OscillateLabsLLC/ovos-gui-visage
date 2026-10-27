/// (namespace, page) -> page widget, keyed by exact name so adding a template is one entry and one file (SPEC 8.2).
/// System templates are shown in the calling skill's own namespace, so they route by page name alone.
library;

import 'package:flutter/widgets.dart';

import '../faults.dart';
import '../protocol/wire_protocol.dart';
import '../state/gui_state.dart';
import '../widgets/notification_list.dart';
import 'alarms_page.dart';
import 'alert_list_page.dart';
import 'blank_page.dart';
import 'clock_page.dart';
import 'confirm_page.dart';
import 'date_page.dart';
import 'error_page.dart';
import 'fallback_page.dart';
import 'forecast_page.dart';
import 'grid_page.dart';
import 'html_frame_page.dart';
import 'idle_page.dart';
import 'image_frame_page.dart';
import 'input_box_page.dart';
import 'list_page.dart';
import 'loading_page.dart';
import 'map_page.dart';
import 'media_pages.dart';
import 'now_playing_page.dart';
import 'ocp_busy_page.dart';
import 'ocp_list_page.dart';
import 'page.dart';
import 'select_page.dart';
import 'status_page.dart';
import 'sun_times_page.dart';
import 'system_face_page.dart';
import 'system_timer_page.dart';
import 'system_weather_page.dart';
import 'table_page.dart';
import 'template_names.dart';
import 'text_frame_page.dart';
import 'time_page.dart';
import 'timer_page.dart';
import 'url_frame_page.dart';
import 'weather_now_page.dart';

const routes = <String, PageBuilder>{
  'ovos-skill-homescreen.openvoiceos/idle': IdlePage.page,
  'ovos-skill-date-time.openvoiceos/time': TimePage.page,
  'ovos-skill-date-time.openvoiceos/date': DatePage.page,
  'ovos-skill-weather.openvoiceos/CurrentWeather': WeatherNowPage.build_,
  'ovos-skill-weather.openvoiceos/SingleDay': WeatherNowPage.build_,
  'ovos-skill-weather.openvoiceos/DailyForecast': ForecastPage.build_,
  'ovos-skill-weather.openvoiceos/HourlyForecast': ForecastPage.build_,
  'ovos-skill-weather.openvoiceos/SunriseSunset': SunTimesPage.page,
  'ovos-skill-alerts.openvoiceos/Timer': TimerPage.page,
  'ovos-skill-alerts.openvoiceos/AlarmsOverviewCard': AlarmsPage.page,
  'ovos-skill-alerts.openvoiceos/ListView': AlertListPage.page,
  // OCP shows PlayerLoader and names the player in playerBackend; the page renders OVOSSyncPlayer, else the fallback.
  'ovos.common_play/PlayerLoader': NowPlayingPage.page,
  'ovos.common_play/OVOSSyncPlayer': NowPlayingPage.page,
  'ovos.common_play/busy': OcpBusyPage.page,
  'ovos.common_play/SuggestionsView': OcpListPage.build_,
  'ovos.common_play/Home': OcpListPage.build_,
};

/// Keyed by canonical name (template_names.dart); a known template missing here shows the fallback, reported.
const templates = <String, PageBuilder>{
  'SYSTEM_face': SystemFacePage.page,
  'SYSTEM_text': TextFramePage.page,
  'SYSTEM_loading': LoadingPage.page,
  'SYSTEM_status': StatusPage.page,
  'SYSTEM_error': ErrorPage.page,
  'SYSTEM_image': ImageFramePage.page,
  'SYSTEM_animated_image': ImageFramePage.page,
  'SYSTEM_list': ListPage.page,
  'SYSTEM_grid': GridPage.page,
  'SYSTEM_table': TablePage.page,
  'SYSTEM_html': HtmlFramePage.page,
  'SYSTEM_url': UrlFramePage.page,
  'SYSTEM_audio_player': AudioPlayerPage.page,
  'SYSTEM_video_player': VideoPlayerPage.page,
  'SYSTEM_media_player': MediaPlayerPage.page,
  'SYSTEM_InputBox': InputBoxPage.page,
  'SYSTEM_clock': ClockPage.page,
  'SYSTEM_timer': SystemTimerPage.page,
  'SYSTEM_weather': SystemWeatherPage.page,
  'SYSTEM_map': MapPage.page,
  'SYSTEM_confirm': ConfirmPage.page,
  'SYSTEM_select': SelectPage.page,
  'SYSTEM_input': InputBoxPage.companion,
};

/// Known templates that have no page yet, and unknown `SYSTEM_` names. Each one is reported the first time it is shown,
/// then falls back quietly.
class TemplateGaps {
  final _reported = <String>{};

  PageBuilder fallbackFor(String template) {
    if (_reported.add(template)) {
      reportFault('routing $template', UnimplementedError('$template has no page yet'), StackTrace.current);
    }
    return FallbackPage.page;
  }

  /// A `SYSTEM_` name outside the GUI-1 vocabulary, which the GUI-1 adapter passes through (gui-1.md 6.5): reported the
  /// first time, and it shows the fallback like any name without a page.
  PageBuilder unknown(String template) {
    if (_reported.add(template)) {
      reportFault('routing $template', ArgumentError.value(template, 'template', 'not a GUI-1 template'), StackTrace.current);
    }
    return FallbackPage.page;
  }
}

final templateGaps = TemplateGaps();

/// Exact skill route first, then the template the page name stands for (by any alias), then the fallback.
PageBuilder resolve(Target? target, {TemplateGaps? gaps}) {
  if (target == null) return (_, _) => const BlankPage();
  final route = routes['${target.namespace}/${target.page}'];
  if (route != null) return route;
  final template = canonicalTemplate(target.page);
  if (template == null) return FallbackPage.page;
  return templates[template] ?? (gaps ?? templateGaps).fallbackFor(template);
}

/// Hosts the current page. A new (namespace, page, index) replaces the subtree, so page state resets; the same
/// target with new data rebuilds the same widget, so a page keeps its tickers and animations across updates.
class PageHost extends StatelessWidget {
  const PageHost({super.key, required this.state, required this.send, required this.notifications, this.protocol});

  final GuiState state;

  /// The GUI socket, handed to every page through its context.
  final GuiSend send;

  /// The stored notification list: its count and the way to open it, for the homescreen's badge.
  final NotificationListController notifications;

  /// Handed to every page (PageContext.protocol).
  final ChosenProtocol? protocol;

  @override
  Widget build(BuildContext context) {
    final target = state.current();
    final ns = target == null ? null : state.namespace(target.namespace);
    final ctx = PageContext(
      namespace: target?.namespace ?? '',
      page: target?.page ?? '',
      events: ns?.events ?? const {},
      send: send,
      showNotifications: notifications.open,
      storedNotifications: notifications.storage.value.length,
      protocol: protocol,
    );
    final data = Json.of(ns?.data ?? const {});
    return KeyedSubtree(key: ValueKey(target?.toString() ?? ''), child: resolve(target)(data, ctx));
  }
}
