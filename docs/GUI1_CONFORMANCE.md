# OVOS-GUI-1 conformance

Spec: `OpenVoiceOS/architecture`, branch `dev`, `gui-1.md` at commit `b6c1583`. Line numbers below are at that
commit. Plan: `docs/GUI1_PLAN.md` section 3.

Status values:

- `none`: Visage does not do this yet.
- `partial`: Visage does some of it; the notes say what is missing.
- `done`: Visage does it and the named test proves it.

`test/conformance_test.dart` reads this file. It fails when a template in `lib/pages/template_names.dart` has no row,
when a status is not one of the three values, when a `done` row names no test, or when a named test file does not
exist. Run it alone with `just conformance`.

## Templates (§3.4)

The eight aliased templates render, but no test is written from the spec's key list. The notes give the keys the page
reads and the keys that no test drives.

| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| `SYSTEM_idle` | §3.4, line 217; §6.9, lines 718–740 | none | — | — | In the unimplemented set. Visage routes only the homescreen skill's `idle` page (`lib/pages/router.dart` line 36). Finding F4, F9. |
| `SYSTEM_loading` | §3.4, line 218 | partial | `lib/pages/loading_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart` | Reads `label`. Unchecked: no page test drives `label`. |
| `SYSTEM_status` | §3.4, line 219 | partial | `lib/pages/status_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart`, `test/gui1_apply_test.dart` | Reads `label`, `success` and the legacy `status`. `success: true` reaches the page from a GUI-1 fixture (`test/gui1_apply_test.dart`, `status_events`); `success: false` is tested in the model only. |
| `SYSTEM_error` | §3.4, line 220 | none | — | — | In the unimplemented set. |
| `SYSTEM_text` | §3.4, line 226 | partial | `lib/pages/text_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/template_pages_test.dart` | Reads `text`, `title`, which is the full spec list. Unchecked: no test is written from the spec's key list. |
| `SYSTEM_image` | §3.4, line 227; §3.5, lines 304–317 | partial | `lib/pages/image_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `image`, `caption`, `title`, `fill`, `background_color`. Unchecked: `background_color` (fixture only). Also accepts absolute paths (`templates_model.dart` line 25), which §3.5 does not require. |
| `SYSTEM_animated_image` | §3.4, line 228 | partial | `lib/pages/image_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart` | Same page and keys as `SYSTEM_image`. Unchecked: no test shows an animated image. |
| `SYSTEM_list` | §3.4, line 229 | none | — | — | In the unimplemented set. |
| `SYSTEM_grid` | §3.4, line 230 | none | — | — | In the unimplemented set. |
| `SYSTEM_table` | §3.4, line 231 | none | — | — | In the unimplemented set. |
| `SYSTEM_html` | §3.4, line 232; §3.6 | partial | `lib/pages/html_frame_page.dart` | `test/template_names_test.dart` | Reads `html`. Unchecked: `html` (route test only). Not read: `resource_url`. |
| `SYSTEM_url` | §3.4, line 233; §3.6 | partial | `lib/pages/url_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `url`, which is the full spec list. Unchecked: no test is written from the spec's key list. |
| `SYSTEM_audio_player` | §3.4, line 239 | none | — | — | In the unimplemented set. |
| `SYSTEM_video_player` | §3.4, line 240 | none | — | — | In the unimplemented set. |
| `SYSTEM_media_player` | §3.4, line 241 | none | — | — | In the unimplemented set. Finding F10. |
| `SYSTEM_clock` | §3.4, line 259 | done | `lib/pages/clock_page.dart`, `lib/pages/time_page.dart`, `lib/pages/every_second.dart` | `test/clock_page_test.dart`, `test/template_names_test.dart` | No keys. Time from the device clock, rebuilt once a second; the date-time skill's ring (`ClockRing`). 12/24-hour follows the device setting (`MediaQuery.alwaysUse24HourFormat`); Visage adds no config key. Session data the template does not define is ignored without a report. `system_clock` fixture. |
| `SYSTEM_timer` | §3.4, line 260 | done | `lib/pages/system_timer_page.dart`, `lib/pages/system_timer_model.dart`, `lib/pages/data_faults.dart` | `test/system_timer_test.dart`, `test/data_faults_test.dart`, `test/template_names_test.dart` | Reads `end_time`, `label`, `count_up`; the alerts skill's `TimerRing`, ticking from the device clock. Past `end_time` counting down: "Time's up" with `+elapsed`. Counting up before `end_time`: `0:00`. Missing or mistyped `end_time`: reported, label over `--:--`. Progress is against the longest remaining time seen, so a late joiner starts at a full ring (finding F20); count-up before `end_time` is unspecified (F21). One timer per namespace: the alerts skill's multi-timer page stays on its legacy route (`ovos-skill-alerts.openvoiceos/Timer`) and has no GUI-1 equivalent until architecture#287 lands (finding F8). No cancel button: no reply leg (§7.2). `system_timer` fixture. |
| `SYSTEM_weather` | §3.4, line 261; §3.5, lines 281–294 | done | `lib/pages/system_weather_page.dart`, `lib/pages/weather_card_model.dart`, `lib/pages/weather_now_page.dart` | `test/system_weather_test.dart`, `test/gui1_recorded_test.dart`, `test/gui1_apply_test.dart`, `test/template_names_test.dart` | Reads all six keys onto the skill's current-weather card (`WeatherNowCard`). `condition` picks a bundled icon by English keyword (finding F18); an `http(s)` or `data:image` `icon` replaces it, a bare path is reported. Temperatures as given, no unit (finding F17). Missing `current_temp` or `condition`: reported, the rest of the card shows. The adapter's recordings (`text_then_weather`, `weather_then_clear`) now render this page, with one report each: they send `current`/`min`/`max`, not the spec keys (finding F19). No forecast: the template has no forecast key, so `forecast_page.dart` is not used. `system_weather` fixture. |
| `SYSTEM_map` | §3.4, line 262; §6.5, line 613 | partial | `lib/pages/map_page.dart`, `lib/pages/map_card_model.dart` | `test/map_page_test.dart`, `test/template_names_test.dart` | Reads all four keys and checks the ranges (latitude ±90, longitude ±180, zoom 1–20); a missing, mistyped or out-of-range value is reported. Renders the §6.5 degradation only: label, a static pin and the coordinates, or "Location unavailable". `zoom` is validated but unused. Open: the map provider and what to show offline (`docs/BACKLOG.md`, GUI-1 templates). `system_map` fixture. |
| `SYSTEM_face` | §3.4, line 263 | partial | `lib/pages/system_face_page.dart` | `test/template_names_test.dart` | Reads `sleeping` (any truthy value, not only a boolean). Unchecked: `sleeping`. |
| `SYSTEM_confirm` | §3.4, lines 288–302 | done | `lib/pages/template_names.dart` | `test/template_names_test.dart` | Reserved. Routes as unknown with no fault, as does `Confirm.qml`. Finding F11. |
| `SYSTEM_select` | §3.4, lines 288–302 | done | `lib/pages/template_names.dart` | `test/template_names_test.dart` | Reserved. Routes as unknown with no fault, as does `Select.qml`. Finding F11. |

`SYSTEM_InputBox` is not a GUI-1 template, so it has no row. It keeps its legacy name only (finding F13).

## Adapter MUST (§8.4)

Visage is the client. The adapter that carries these clauses is `ovos-gui-plugin-visage` (plan phase 2), which is
being written. A clause is `partial` only where Visage already does the client half.

| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| Discoverable via the adapter entry-point group | §8.4, line 847; §6.1 | none | — | — | Adapter not written. |
| Construct quickly, non-blocking, server loop on a background thread | §8.4, lines 848–849; §6.2 | none | — | — | Adapter not written. |
| No exception escapes a handler or hook | §8.4, line 850; §6.6 | none | — | — | Adapter not written. |
| Never block the dispatch path; never mutate GUI-service state | §8.4, lines 851–852; §6.6 | none | — | — | Adapter not written. |
| Per-session events go to clients on that `session_id`; `"default"` is not a wildcard | §8.4, lines 853–854; §5.1 | partial | `lib/protocol/gui1_frames.dart`, `lib/state/gui1_apply.dart` | `test/gui1_apply_test.dart`, `test/gui1_client_test.dart` | Client half: Visage declares `default` in `hello`, refuses a `welcome` for another session, and reports and ignores a frame for another session. The session is not configurable yet (plan P3.7). Adapter half in `ovos-gui-plugin-visage`. |
| Never fail on a template it cannot render: render, or decline as a no-op | §8.4, lines 855–856; §6.5 | partial | `lib/pages/router.dart`, `lib/pages/template_names.dart`, `lib/state/gui1_apply.dart` | `test/template_names_test.dart`, `test/router_test.dart`, `test/gui1_apply_test.dart` | Client half: every known template without a page and every unknown name shows the fallback page and never throws. Over GUI-1 an unknown `SYSTEM_` name is also reported once (`TemplateGaps.unknown`, `unknown_template` fixture). Adapter half in `ovos-gui-plugin-visage`. |
| Never fail on a status event it does not recognise | §8.4, line 857; §5.3 | partial | `lib/screen_link.dart`, `lib/attention.dart`, `lib/status_topics.dart` | `test/gui1_apply_test.dart`, `test/status_topics_test.dart` | Client half: a GUI-1 `status` frame goes to `Attention`, keyed by the §5.3 names with the legacy topics as aliases (`lib/status_topics.dart`). A topic Visage does not follow changes nothing and is reported once per name (`Gui1Gaps.unknownStatus`). Visage follows 12 of the 16 §5.3 topics; `ovos.stt.failed`, `ovos.intent.handler.error`, `ovos.listener.sleep` and `ovos.listener.awoken` are plan P3.6. Adapter half in `ovos-gui-plugin-visage`. |
| Release per-namespace state on namespace-deactivated | §8.4, line 858; §6.6, lines 690–692 | partial | `lib/state/gui_state.dart`, `lib/state/gui1_apply.dart` | `test/gui_state_test.dart`, `test/gui1_apply_test.dart` | Client half: a GUI-1 `deactivated` frame drops the namespace, its page and its data (`two_namespaces_deactivate` fixture). The legacy path still keeps the data: `mycroft.session.list.remove` clears only the pages. Adapter half in `ovos-gui-plugin-visage`. |

## Adapter SHOULD (§8.5)

| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| Degrade an unrenderable template to the nearest renderable presentation | §8.5, lines 862–863; §6.5 | none | `lib/pages/fallback_page.dart` | — | The fallback page is a debug dump of the session data, not a degraded presentation. |
| Broadcast status events and device-wide signals to all clients | §8.5, lines 864–865; §5.3 | none | — | — | Adapter not written; no sessions in Visage. |
| Report connection status | §8.5, lines 866–867; §6.8 | none | — | — | Adapter not written. OPM's adapter base has no hook for it (plan section 1.4). |
| Re-read state from the query surface, do not cache `data` | §8.5, lines 868–869; §6.6, §6.7 | partial | `lib/state/gui1_apply.dart` | `test/gui1_apply_test.dart` | Client half: every `template`, `session_update` and `snapshot` replaces the namespace's data with the full map; Visage never merges. Adapter half in `ovos-gui-plugin-visage`. |

## GUI-1 wire client (WIRE.md)

Not spec clauses: the adapter ⇄ Visage protocol (`gui1-upstream/WIRE.md`, plan section 2.2), which the spec leaves to
the backend (§1, §8.6).

| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| `hello` first; `welcome` within 3 s; `error` or anything else ends the probe | WIRE.md, Handshake | done | `lib/protocol/gui1_client.dart`, `lib/protocol/gui1_frames.dart` | `test/gui1_client_test.dart`, `test/gui1_frames_test.dart` | A mismatched protocol, version or session in `welcome` is also a failed probe. Tested against a scripted socket and a real local websocket. |
| Every server frame decoded into a typed event | WIRE.md, Server → client frames | done | `lib/protocol/gui1_frames.dart` | `test/gui1_frames_test.dart` | An unknown type or a bad field is reported with the payload; the socket stays. |
| `template` before `activated` activates; `session_update` for an unseen namespace; any order of the three gives one end state | WIRE.md, Server → client frames | done | `lib/state/gui1_apply.dart` | `test/gui1_apply_test.dart`, `test/gui1_recorded_test.dart` | `template` before `activated` is ovos-gui's normal order. The adapter's recorded fixtures (`test/fixtures/gui1/recorded/`) replay to the same state as their snapshots. |
| `snapshot` replaces the session's state, index 0 on top, `template: null` holds data only | WIRE.md, Server → client frames | done | `lib/state/gui1_apply.dart` | `test/gui1_apply_test.dart` | `snapshot_late_joiner` fixture. |
| `idle` empties the stack when this session's is already empty, and is ignored (logged once) otherwise | WIRE.md, Server → client frames | done | `lib/state/gui1_apply.dart` | `test/gui1_apply_test.dart`, `test/gui1_recorded_test.dart` | Finding F16. The screen goes blank under the full face; the backend-owned resting display is plan P3.5. |
| `protocol: auto, gui1, legacy`; `VISAGE_PROTOCOL`, `VISAGE_GUI1_URL` | WIRE.md, Client behaviour | done | `lib/app_config.dart`, `lib/protocol/wire_protocol.dart` | `test/app_config_test.dart`, `test/gui1_frames_test.dart` | |
| `auto` falls back to legacy; no switch mid-run; a reconnect probes again; the choice is logged and in the menu | WIRE.md, Client behaviour | done | `lib/protocol/gui_link.dart`, `lib/window/status_menu.dart` | `test/gui1_client_test.dart`, `test/status_menu_test.dart` | Not verified live against legacy ovos-gui after this change (Visage was never pointed at Mike's OVOS). |
