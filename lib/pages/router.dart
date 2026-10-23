/// (namespace, page) -> page widget, keyed by exact name so adding a template is one entry and one file (SPEC 8.2).
/// System templates are shown in the calling skill's own namespace, so they route by page name alone.
library;

import 'package:flutter/widgets.dart';

import '../state/gui_state.dart';
import 'alarms_page.dart';
import 'alert_list_page.dart';
import 'blank_page.dart';
import 'date_page.dart';
import 'fallback_page.dart';
import 'forecast_page.dart';
import 'html_frame_page.dart';
import 'idle_page.dart';
import 'image_frame_page.dart';
import 'input_box_page.dart';
import 'loading_page.dart';
import 'now_playing_page.dart';
import 'ocp_busy_page.dart';
import 'ocp_list_page.dart';
import 'page.dart';
import 'status_page.dart';
import 'sun_times_page.dart';
import 'system_face_page.dart';
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

const templates = <String, PageBuilder>{
  'SYSTEM_Face': SystemFacePage.page,
  'SYSTEM_TextFrame': TextFramePage.page,
  'SYSTEM_Loading': LoadingPage.page,
  'SYSTEM_Status': StatusPage.page,
  'SYSTEM_ImageFrame': ImageFramePage.page,
  'SYSTEM_AnimatedImageFrame': ImageFramePage.page,
  'SYSTEM_HtmlFrame': HtmlFramePage.page,
  'SYSTEM_UrlFrame': UrlFramePage.page,
  'SYSTEM_InputBox': InputBoxPage.page,
};

PageBuilder resolve(Target? target) {
  if (target == null) return (_, _) => const BlankPage();
  return routes['${target.namespace}/${target.page}'] ?? templates[target.page] ?? FallbackPage.page;
}

/// Hosts the current page. A new (namespace, page, index) replaces the subtree, so page state resets; the same
/// target with new data rebuilds the same widget, so a page keeps its tickers and animations across updates.
class PageHost extends StatelessWidget {
  const PageHost({super.key, required this.state, required this.send});

  final GuiState state;

  /// The GUI socket, handed to every page through its context.
  final GuiSend send;

  @override
  Widget build(BuildContext context) {
    final target = state.current();
    final ns = target == null ? null : state.namespace(target.namespace);
    final ctx = PageContext(
      namespace: target?.namespace ?? '',
      page: target?.page ?? '',
      events: ns?.events ?? const {},
      send: send,
    );
    final data = Json.of(ns?.data ?? const {});
    return KeyedSubtree(key: ValueKey(target?.toString() ?? ''), child: resolve(target)(data, ctx));
  }
}
