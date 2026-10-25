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
| `SYSTEM_error` | §3.4, line 220 | done | `lib/pages/error_page.dart`, `lib/pages/content_models.dart`, `lib/pages/template_keys.dart` | `test/content_models_test.dart`, `test/content_pages_test.dart`, `test/template_names_test.dart` | Reads `label` (req) and `detail`, which is the full spec list. A missing `label` is reported and the page shows "Something went wrong"; a number or boolean is reported and shown as text, another type is reported and dropped. Fixture `test/fixtures/gui1/system_error.jsonl`. |
| `SYSTEM_text` | §3.4, line 226 | partial | `lib/pages/text_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/template_pages_test.dart` | Reads `text`, `title`, which is the full spec list. Unchecked: no test is written from the spec's key list. |
| `SYSTEM_image` | §3.4, line 227; §3.5, lines 304–317 | partial | `lib/pages/image_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `image`, `caption`, `title`, `fill`, `background_color`. Unchecked: `background_color` (fixture only). Also accepts absolute paths (`templates_model.dart` line 25), which §3.5 does not require. |
| `SYSTEM_animated_image` | §3.4, line 228 | partial | `lib/pages/image_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart` | Same page and keys as `SYSTEM_image`. Unchecked: no test shows an animated image. |
| `SYSTEM_list` | §3.4, line 229; §3.5 | done | `lib/pages/list_page.dart`, `lib/pages/content_models.dart`, `lib/pages/template_keys.dart` | `test/content_models_test.dart`, `test/content_pages_test.dart`, `test/template_names_test.dart` | Reads `title` and `items[]` `{title (req), subtitle, image}`, the full spec list. Rows scroll. `image` is an `http(s)` URL or a `data:image/` URI; a bare path or anything else is reported and the row shows without the thumbnail. An item without `title` is reported and shows its subtitle in its place. Absent `items` is an empty list, not a fault (finding F17). Fixture `test/fixtures/gui1/system_list.jsonl`. |
| `SYSTEM_grid` | §3.4, line 230; §3.5 | done | `lib/pages/grid_page.dart`, `lib/pages/content_models.dart`, `lib/pages/template_keys.dart` | `test/content_models_test.dart`, `test/content_pages_test.dart`, `test/template_names_test.dart` | Reads `title` and `items[]` `{image (req), title}`, the full spec list. Columns: as many tiles of at least 180 px as fit, one to six (`gridColumns`; two on the 480 x 800 frame). A tile without a usable image is reported and shows its title on a plain tile. Fixture `test/fixtures/gui1/system_grid.jsonl`. Findings F17, F20. |
| `SYSTEM_table` | §3.4, line 231 | done | `lib/pages/table_page.dart`, `lib/pages/content_models.dart`, `lib/pages/template_keys.dart` | `test/content_models_test.dart`, `test/content_pages_test.dart`, `test/template_names_test.dart` | Reads `title`, `columns` (req) and `rows` (req), the full spec list. A row shorter than `columns` is reported and padded with empty cells; a longer one is reported and truncated. Without `columns`: reported, no header. Without `rows`: reported, the header and "No rows". Columns share the width equally; nothing scrolls sideways, so a wide table wraps its cells. Findings F18, F19. Fixture `test/fixtures/gui1/system_table.jsonl`. |
| `SYSTEM_html` | §3.4, line 232; §3.6 | partial | `lib/pages/html_frame_page.dart` | `test/template_names_test.dart` | Reads `html`. Unchecked: `html` (route test only). Not read: `resource_url`. |
| `SYSTEM_url` | §3.4, line 233; §3.6 | partial | `lib/pages/url_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `url`, which is the full spec list. Unchecked: no test is written from the spec's key list. |
| `SYSTEM_audio_player` | §3.4, line 239 | none | — | — | In the unimplemented set. |
| `SYSTEM_video_player` | §3.4, line 240 | none | — | — | In the unimplemented set. |
| `SYSTEM_media_player` | §3.4, line 241 | none | — | — | In the unimplemented set. Finding F10. |
| `SYSTEM_clock` | §3.4, line 259 | none | — | — | In the unimplemented set. |
| `SYSTEM_timer` | §3.4, line 260 | none | — | — | In the unimplemented set. Finding F8. |
| `SYSTEM_weather` | §3.4, line 261 | none | — | — | In the unimplemented set. Over GUI-1 it shows the fallback with one report (`text_then_weather` fixture). |
| `SYSTEM_map` | §3.4, line 262 | none | — | — | In the unimplemented set. |
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
| Degrade an unrenderable template to the nearest renderable presentation | §8.5, lines 862–863; §6.5 | partial | `lib/pages/fallback_page.dart` | `test/fallback_page_test.dart` | Client half: a template or page without a widget shows its `image` as the image page would, else its `title` and `text` as the text page would, else the debug dump (`degradedPage`). The per-template degradations of §6.5 that need other keys (`SYSTEM_weather` as a one-line summary, `SYSTEM_map` as its label, the players as title and artist) are not done; those templates are P3.3 and P3.4. Adapter half in `ovos-gui-plugin-visage`. |
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
