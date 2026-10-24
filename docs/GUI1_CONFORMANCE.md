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
| `SYSTEM_status` | §3.4, line 219 | partial | `lib/pages/status_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `label`, `success` and the legacy `status`. `success` is tested in the model only; the page test uses legacy `status`. |
| `SYSTEM_error` | §3.4, line 220 | none | — | — | In the unimplemented set. |
| `SYSTEM_text` | §3.4, line 226 | partial | `lib/pages/text_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/template_pages_test.dart` | Reads `text`, `title`, which is the full spec list. Unchecked: no test is written from the spec's key list. |
| `SYSTEM_image` | §3.4, line 227; §3.5, lines 304–317 | partial | `lib/pages/image_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `image`, `caption`, `title`, `fill`, `background_color`. Unchecked: `background_color` (fixture only). Also accepts absolute paths (`templates_model.dart` line 24), which §3.5 does not require. |
| `SYSTEM_animated_image` | §3.4, line 228 | partial | `lib/pages/image_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart` | Same page and keys as `SYSTEM_image`. Unchecked: no test shows an animated image. |
| `SYSTEM_list` | §3.4, line 229 | none | — | — | In the unimplemented set. |
| `SYSTEM_grid` | §3.4, line 230 | none | — | — | In the unimplemented set. |
| `SYSTEM_table` | §3.4, line 231 | none | — | — | In the unimplemented set. |
| `SYSTEM_html` | §3.4, line 232; §3.6 | partial | `lib/pages/html_frame_page.dart` | `test/template_names_test.dart` | Reads `html`. Unchecked: `html` (route test only). Not read: `resource_url`. |
| `SYSTEM_url` | §3.4, line 233; §3.6 | partial | `lib/pages/url_frame_page.dart`, `lib/pages/templates_model.dart` | `test/template_names_test.dart`, `test/templates_model_test.dart`, `test/template_pages_test.dart` | Reads `url`, which is the full spec list. Unchecked: no test is written from the spec's key list. |
| `SYSTEM_audio_player` | §3.4, line 239 | none | — | — | In the unimplemented set. |
| `SYSTEM_video_player` | §3.4, line 240 | none | — | — | In the unimplemented set. |
| `SYSTEM_media_player` | §3.4, line 241 | none | — | — | In the unimplemented set. Finding F10. |
| `SYSTEM_clock` | §3.4, line 259 | none | — | — | In the unimplemented set. |
| `SYSTEM_timer` | §3.4, line 260 | none | — | — | In the unimplemented set. Finding F8. |
| `SYSTEM_weather` | §3.4, line 261 | none | — | — | In the unimplemented set. |
| `SYSTEM_map` | §3.4, line 262 | none | — | — | In the unimplemented set. |
| `SYSTEM_face` | §3.4, line 263 | partial | `lib/pages/system_face_page.dart` | `test/template_names_test.dart` | Reads `sleeping` (any truthy value, not only a boolean). Unchecked: `sleeping`. |
| `SYSTEM_confirm` | §3.4, lines 288–302 | done | `lib/pages/template_names.dart` | `test/template_names_test.dart` | Reserved. Routes as unknown with no fault, as does `Confirm.qml`. Finding F11. |
| `SYSTEM_select` | §3.4, lines 288–302 | done | `lib/pages/template_names.dart` | `test/template_names_test.dart` | Reserved. Routes as unknown with no fault, as does `Select.qml`. Finding F11. |

`SYSTEM_InputBox` is not a GUI-1 template, so it has no row. It keeps its legacy name only (finding F13).

## Adapter MUST (§8.4)

Visage is the client. The adapter that carries these clauses is `ovos-gui-plugin-visage` (plan phase 2), which does
not exist yet. A clause is `partial` only where Visage already does the client half.

| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| Discoverable via the adapter entry-point group | §8.4, line 847; §6.1 | none | — | — | Adapter not written. |
| Construct quickly, non-blocking, server loop on a background thread | §8.4, lines 848–849; §6.2 | none | — | — | Adapter not written. |
| No exception escapes a handler or hook | §8.4, line 850; §6.6 | none | — | — | Adapter not written. |
| Never block the dispatch path; never mutate GUI-service state | §8.4, lines 851–852; §6.6 | none | — | — | Adapter not written. |
| Per-session events go to clients on that `session_id`; `"default"` is not a wildcard | §8.4, lines 853–854; §5.1 | none | — | — | No `session_id` anywhere in `lib/`. |
| Never fail on a template it cannot render: render, or decline as a no-op | §8.4, lines 855–856; §6.5 | partial | `lib/pages/router.dart`, `lib/pages/template_names.dart` | `test/template_names_test.dart`, `test/router_test.dart` | Client half: every known template without a page and every unknown name shows the fallback page and never throws. Adapter half not written. |
| Never fail on a status event it does not recognise | §8.4, line 857; §5.3 | none | — | — | Adapter not written. Visage does not read the §5.3 `ovos.*` set yet. Cannot tell from code how an unknown core-bus topic is handled; no test covers it. |
| Release per-namespace state on namespace-deactivated | §8.4, line 858; §6.6, lines 690–692 | partial | `lib/state/gui_state.dart` | `test/gui_state_test.dart` | Legacy path only: `mycroft.session.list.remove` clears the namespace's pages (lines 150–160) but keeps its data. No GUI-1 namespace-deactivated event yet. |

## Adapter SHOULD (§8.5)

| Item | Spec reference | Status | Visage files | Test | Notes |
|---|---|---|---|---|---|
| Degrade an unrenderable template to the nearest renderable presentation | §8.5, lines 862–863; §6.5 | none | `lib/pages/fallback_page.dart` | — | The fallback page is a debug dump of the session data, not a degraded presentation. |
| Broadcast status events and device-wide signals to all clients | §8.5, lines 864–865; §5.3 | none | — | — | Adapter not written; no sessions in Visage. |
| Report connection status | §8.5, lines 866–867; §6.8 | none | — | — | Adapter not written. OPM's adapter base has no hook for it (plan section 1.4). |
| Re-read state from the query surface, do not cache `data` | §8.5, lines 868–869; §6.6, §6.7 | none | — | — | Adapter not written. |
