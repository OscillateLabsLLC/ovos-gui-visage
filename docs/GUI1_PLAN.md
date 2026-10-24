# OVOS-GUI-1 reference implementation: plan

Status: plan, 2026-10-24. Owner: Mike (Oscillate Labs). Spec: OVOS-GUI-1 v1, Draft
(`OpenVoiceOS/architecture`, branch `dev`, `gui-1.md`, head `b6c1583`).

Visage becomes the reference render backend for OVOS-GUI-1. That takes three pieces of work:

1. **Visage** (this repo) learns to speak GUI-1 natively.
2. **The Python service side** upstream: the adapter base class in ovos-plugin-manager (OPM) and
   the ovos-gui rework. Both are stalled drafts.
3. **`ovos-gui-plugin-visage`**, a new `opm.gui_adapter` plugin in a new OscillateLabsLLC repo.
   It goes to OpenVoiceOS when it is done.

Ground rules agreed with Jarbas and Mike:

- The spec does not settle until it is implemented. Visage helps to write it.
- No spec changes are planned upstream, except a rename of the old `__`-prefixed keys.
- The Qt GUI is shelved upstream.
- We do not work around a spec problem. We fix the spec. Each deviation gets a spec PR on the
  same day and a row in `docs/GUI1_FINDINGS.md` (section 6).

All upstream facts below come from clones made on 2026-10-24. Paths are relative to each repo.

---

## 1. Current state

### 1.1 What the spec says

- A producer names one template from a closed `SYSTEM_*` set and sends flat session data
  (`gui-1.md` §3, lines 124–331). 20 templates are defined. `SYSTEM_confirm` and
  `SYSTEM_select` are reserved and producers must not emit them (lines 288–302).
- Wire: `gui.value.set`, `gui.page.show`, `gui.clear.namespace`. `__from` and `__idle` are
  reserved and the service strips them (§4.1, lines 342–367). An explicit `null` removes a key
  (§3.3, lines 183–190).
- `session_id` is the only routing key. `"default"` is not a wildcard (§5.1, lines 487–504).
  Shared screens share a `session_id` (§5.2).
- The GUI service is a hub. It holds per-session namespace stacks, fans out to every adapter,
  renders nothing and runs no client transport (§2.1, lines 91–95; §8.3, line 843).
- Adapters are `opm.gui_adapter` plugins. They get template events, session updates,
  activate/deactivate hooks, a device-wide idle hook and status events (§6.3, lines 600–629).
- Status events are a fixed table of 16 `ovos.*` topics (§5.3, lines 533–556, PR #286).
- The resting display belongs to the backend. No app may own a home screen (§6.9). Ambient data
  arrives as `gui.ambient.weather` and `gui.ambient.notifications` (§6.9.1, PR #289).
- Images are `http(s)` or `data:` only. No filesystem paths on the wire (§3.5).
- Transport between an adapter and its clients is out of scope (§1, lines 59–61). That is our
  freedom: section 2.2 decides it.

### 1.2 What exists in code

| Piece | Where | State |
|---|---|---|
| Adapter base `AbstractGUIPlugin`, `OVOSGUIAdapterFactory`, `PluginTypes.GUI_ADAPTER` | OPM PR #377, branch `gui` | 4 commits, last 2026-10-02. Base `b039891` (2026-07-15). 63 dev commits behind. Merges into dev with no conflict (`git merge-tree`). |
| GUI-1 conformance on the legacy service | ovos-gui PR #117, `feat/gui1-service-conformance` | 1 commit, 2026-08-13. Base 2026-08-11, 15 dev commits behind. Conflicts with dev in `pyproject.toml`. |
| Adapter-dispatch rework | ovos-gui PR #112, `feat/gui-rework-landing` | 7 commits, last 2026-07-15. Base 2026-06-28, 21 dev commits behind. Conflicts with dev in `namespace.py`, `service.py`, `pyproject.toml`. |
| Legacy Qt adapter (18181 websocket, `HomescreenManager`) | `ovos-legacy-mycroft-gui-plugin` `master` | Registers `opm.gui_adapter`. Session-id work sits unmerged on branch `feat/session-id-contract` (2026-06-20). |
| Producer `GUIInterface` | ovos-bus-client `dev` (2.11.29a1) | PR #238 (merged 2026-09-25, commit `c0ae994`) fixed null and image wire shapes. Still emits legacy frame names. |
| Frame-name rename | ovos-bus-client branch `gui_depr` | 1 commit, 2026-06-25. Conflicts with dev in `apis/gui.py`. |
| Visage | this repo, v2.4.0 | Legacy 18181 client only. No `session_id` anywhere in `lib/`. |

### 1.3 Dependency graph

```
architecture gui-1.md (Draft, moving)
        |
OPM #377 (AbstractGUIPlugin, opm.gui_adapter) ----------------------+
        |                                                           |
ovos-gui #117 (SYSTEM_ gate, aliases, per-session stacks, legacy)   |
        |   conflicts with #112 in 4 files                          |
ovos-gui #112 (adapters replace bus.py; QML and homescreen removed) |
        |                                                           |
   +----+-------------------------------+                           |
   |                                    |                           |
legacy-mycroft-gui-plugin         ovos-gui-plugin-visage  <---------+
(18181, Qt, homescreen.data.*)    (new; Visage wire)
   |                                    |
mycroft-gui-qt5 / ovos-shell      Visage (Flutter: desktop, web via sidecar)
(shelved)
```

Not stated anywhere upstream, found by diffing: **#117 and #112 are siblings, not a stack.**
Both branch from dev. #117 keeps the 18181 websocket inside ovos-gui (`namespace.py` imports
`send_message_to_gui, GUIWebsocketHandler`, line 56) and has no adapter dispatch at all. #112
deletes `bus.py`, `homescreen.py`, `extensions.py` and all QML, and dispatches only to adapters.
Merging them conflicts in `namespace.py`, `service.py`, `pyproject.toml` and
`test/unittests/test_namespace.py`. "Rebase #112 onto #117" means porting #117's ideas into
#112's model, not a mechanical rebase.

### 1.4 What drifted since August

Spec PRs merged after the code was written. Neither ovos-gui branch implements them:

| Spec change | Merged | #117 | #112 |
|---|---|---|---|
| `null` removes a key (§3.3, §4.2) | 2026-09 | no: `_update_namespace_data` stores the value (lines 1045–1058) | no: same code (lines 661–673) |
| Diagnostic for an unknown `SYSTEM_*` name (§3.2) | 2026-09 | no | no |
| Status-event table of `ovos.*` topics (§5.3, #286) | 2026-10-23 | no: forwards `recognizer_loop:*`, `speak`, `enclosure.*` | partly: 4 `SpecMessage` topics plus the legacy list (lines 292–345) |
| Ambient data `gui.ambient.*` (§6.9.1, #289) | 2026-10-23 | no | no |
| Weather `condition_code`, `forecast` (#288) | 2026-10-23 | n/a (adapter side) | n/a |
| Visemes `ovos.audio.output.visemes` (#290) | 2026-10-23 | no | no |

Code drift on dev since the branches:

- ovos-gui dev added the system resource cache fix (#132, 2026-09-28). #112 deletes the QML
  resources that cache serves.
- ovos-gui dev now accepts OPM 3 (#137, 2026-10-22). #112 pins `ovos-plugin-manager>=2.5.0a1,<3.0.0`
  and adds a new dependency `ovos-spec-tools>=0.9.0a1` (`pyproject.toml` lines 21, 26).
- OPM dev released 3.1.0a1 on 2026-10-22. #377 is still against the July base.

Other gaps found in the adapter base (OPM `gui` branch, `ovos_plugin_manager/templates/gui.py`):

- `handle_show_media_player` documents `ocp_*` keys (lines 224–241). The spec uses `media_*`
  keys (`gui-1.md` line 241).
- `on_status_event` documents legacy names `recognizer_loop:wakeword` and `speak`
  (lines 322–331).
- No `any_client_connected()` hook. Spec §6.8 and the #112 contract (`CONTRACT.md`) expect it.
- The module imports `ovos_gui.homescreen` (lines 9–23). #112 deletes that module.
- In #112, `on_session_update` gets the delta of one message, not the merged map that §4.2 and
  §6.3 require (`namespace.py` lines 656–659). `on_idle` is never called. `__idle` is read with
  `message.data["__idle"]` and raises `KeyError` when it is omitted (line 445); #117 fixed that
  with `.get` (line 770).

Producer side (ovos-bus-client `dev`, `ovos_bus_client/apis/gui.py`):

- Still emits `SYSTEM_TextFrame`, `SYSTEM_ImageFrame`, `SYSTEM_Status`, `SYSTEM_Loading`,
  `SYSTEM_Face` and the other legacy names (lines 622–846).
- `show_status_animation` sends `status: "Enabled" | "Disabled"`. The spec key is
  `success` (boolean) (line 660; `gui-1.md` line 219).
- Sends `__idle: null` when unset. The spec says omit it. Commit `c0ae994` keeps the `null` on
  purpose: every released ovos-gui raises `KeyError` on an absent `__idle`. This is a live,
  documented deviation that waits on ovos-gui.

Legacy adapter (`ovos-legacy-mycroft-gui-plugin` `master`):

- It sends `SYSTEM:<File>.qml` URIs. The QML lives in the Qt client, not in the plugin
  (`page.py` lines 36–49). The repo ships zero `.qml` files. The new pages (`List.qml`,
  `Weather.qml`, `Map.qml` and others, `__init__.py` lines 45–73) exist only if ovos-shell
  ships them. With Qt shelved, nobody renders them.
- It adds three non-spec names: `SYSTEM_ocp_now_playing`, `SYSTEM_ocp_search`,
  `SYSTEM_ocp_playlist` (lines 71–73). §3.1 forbids invented names.
- Its handlers take `site_id`, not `session_id` (lines 159–347).
- `HomescreenManager` emits `homescreen.data.*` and reads `skill-ovos-weather` private topics
  (`homescreen.py` lines 1–22, 104, 180). §6.9.1 replaces this with `gui.ambient.*`.

Not verified: whether ovos-core, ovos-dinkum-listener or ovos-audio emit any of the §5.3
`ovos.*` topics or `ovos.audio.output.visemes` yet. I did not clone them. Nothing in the five
cloned repos emits `gui.ambient.*`. Open state of architecture PR #287 (multi-timer) not checked;
`gh` was not available to this agent.

### 1.5 Visage today

- **Transport.** `GuiClient` announces on the core bus (`mycroft.gui.connected`, framework
  `html`), waits for `mycroft.gui.port`, then holds the 18181 socket (`lib/protocol/gui_client.dart`
  lines 87–120). A second socket goes to the core bus for attention, visemes, notifications,
  volume and typed commands (`lib/protocol/core_bus.dart`).
- **Routing.** `lib/pages/router.dart` resolves a `(namespace, page)` pair. First an exact
  skill route (`routes`, lines 33–51, 16 skill pages). Then a template route by page name
  (`templates`, lines 53–63, 9 legacy names). Then `FallbackPage`.
- **State.** `GuiState` mirrors one ovos-gui stack (`lib/state/gui_state.dart`). It knows
  nothing of sessions. The idle page is the homescreen skill's namespace
  (`defaultIdleNamespace`, line 13).
- **Multiple displays.** Each Visage process announces its own `gui_id`
  (`ovos-gui-visage-<ms % 100000>`, `lib/main.dart` line 141). Legacy ovos-gui sends the same
  stream to every client, so every display mirrors the one default stack. The web build behind
  the sidecar is one more client of that kind. Each client runs its own `WidgetManager`, so the
  notification store is per display (`docs/BACKLOG.md`, Interactive notifications). There is
  no per-display state and no session concept.
- **Images.** `imageSource` accepts `data:image/`, `http(s)` and absolute paths
  (`lib/pages/templates_model.dart` line 24). The desktop reads `~/.cache/ovos_gui` from disk.
- **Typed commands** go out with no session context (`lib/protocol/utterance.dart`), so they
  always land in `"default"`.
- **Fixtures.** `test/fixtures/*.jsonl` (incoming GUI traffic), `corebus/`, `outgoing/` and
  `expected/` (state snapshots that `gui_state_test` must match).

---

## 2. Target architecture

### 2.1 Diagram

```
 skills / OCP / weather / notifications           (producers: GUIInterface)
        |  gui.page.show, gui.value.set, gui.clear.namespace, gui.ambient.*
        v
 core bus :8181  ---- ovos.listener.*, ovos.audio.output.*, ovos.intent.* (status) ----+
        |                                                                              |
        v                                                                              |
 ovos-gui (GUI-1 hub: per-session stacks, strip __ keys, null removal, status table) <-+
        |  dispatch_template / on_session_update / on_namespace_(de)activated /
        |  on_idle / on_status_event         (in process, every adapter)
        v
 +-------------------------------+-----------------------------------+
 | opm.gui_adapter plugins       |                                   |
 |                               |                                   |
 | ovos-gui-plugin-visage        |  ovos-legacy-mycroft-gui-plugin   |
 |  ws :18182 /gui1 (JSON)       |   ws :18181 (mycroft-gui proto)   |
 +---------------+---------------+------------------+----------------+
                 |                                  |
     +-----------+-----------+                      |  fallback path, kept
     |                       |                      |
 Visage desktop       sidecar (nginx) /gui1 /core   +--> Visage legacy mode
 (macOS, Linux)              |                           (old ovos-gui, today)
                      Visage web build (phone, tablet)
```

Visage keeps the core bus socket for the things GUI-1 does not cover: typed commands, volume,
notification actions. Status events reach it through the adapter instead, so a remote client
needs no core-bus access for display.

### 2.2 Wire protocol: adapter ⇄ Visage

Decision: **JSON text frames over one websocket. Each server frame mirrors one adapter call.**
No new framing, no binary, no compression. Reasons:

- The adapter base already defines the exact call set (OPM `templates/gui.py`). A 1:1 frame per
  call means the adapter is a thin, testable relay with no translation logic.
- Visage already speaks JSON over websockets on two sockets and records them as `.jsonl`
  fixtures. The same tooling records this one.
- The spec leaves transport to the backend (§1, §8.6). We can change this protocol without a
  spec PR. It is versioned so that we can.

**Handshake** (client first):

```json
{"type": "hello", "protocol": "ovos-gui-1", "version": 1, "session_id": "default", "client": "visage/2.5.0"}
```

The server answers `welcome` with the same `protocol`, the `version` it chose, the
`session_id` it accepted and its own name. It then sends one `snapshot` for that session: the
stack order, each namespace's active template and its current data. The snapshot comes from the
ovos-gui query surface (§6.7). An unknown `protocol` or `version` gets
`{"type": "error", "reason": "..."}` and a close.

**Server → client frames:**

| `type` | Fields | Adapter call | Delivery |
|---|---|---|---|
| `template` | `skill_id`, `template`, `data`, `session_id` | `handle_show_<x>` via `dispatch_template` | clients on `session_id` |
| `session_update` | `skill_id`, `data`, `session_id` | `on_session_update` | clients on `session_id` |
| `activated` | `skill_id`, `session_id` | `on_namespace_activated` | clients on `session_id` |
| `deactivated` | `skill_id`, `session_id` | `on_namespace_deactivated` | clients on `session_id` |
| `idle` | (none) | `on_idle` | all clients |
| `status` | `event_name`, `data`, `session_id` | `on_status_event` | all clients |
| `snapshot` | `session_id`, `stack: [{skill_id, template, data}]` | state query | the one client |

`template` carries the spec name (`SYSTEM_weather`), never a handler name. The adapter
overrides `dispatch_template` once and does not need 22 handler methods. Unknown `SYSTEM_*`
names pass through. Visage degrades them (§6.5).

**Client → server:** only `hello` in version 1. GUI-1 defines no reply leg (§7.2). Media
transport belongs to the media subsystem (§7.1). Visage keeps sending its interaction messages
on the core bus, as it does today.

**Sessions.** One connection declares one `session_id`. A screen that wants a different
session reconnects. The adapter keeps a map `session_id → set(connections)` and nothing else.

**Detection in Visage.** Config key `protocol`: `auto` (default), `gui1` or `legacy`.
`VISAGE_PROTOCOL` overrides it. In `auto`, Visage opens the GUI-1 endpoint and sends `hello`.
A `welcome` within 3 s selects GUI-1. A refused connection, a timeout or an `error` selects
the legacy path (`mycroft.gui.connected` negotiation). Visage logs the choice and shows it in
the menu. It does not switch protocols during a session; a reconnect probes again.

Why probe, not ask on the core bus: the probe works the same through the sidecar, where the
web build may have no core bus.

**Endpoints.** Adapter config `host` (default `127.0.0.1`), `port` (default `18182`), path
`/gui1`. Not verified: that 18182 is free on a stock OVOS install.

**Sidecar.** Add `location /gui1` that proxies to the adapter, beside `/core` and `/gui`.
Under GUI-1 images are `http(s)` or `data:`, so `/res/` and `/res-abs/` serve only the legacy
path. Authentication and TLS stay at the sidecar, as now.

### 2.3 The three pieces after the work

| Piece | Owns | Does not own |
|---|---|---|
| ovos-gui | stacks per session, `__` stripping, null removal, `__idle` timers, status forwarding, ambient cache, query surface, diagnostics | any socket to clients, any rendering, any home screen |
| ovos-gui-plugin-visage | websocket server, session map, handshake, snapshot on connect, `any_client_connected` | state (it re-reads from ovos-gui), rendering |
| Visage | rendering of every template, degradation, resting display from ambient data, face from status events | session lifecycle, producer data |

---

## 3. Conformance matrix

### 3.1 Templates

"Legacy name" is what ovos-bus-client `dev` emits today, or the QML file the legacy adapter
asks for. "Visage today" is the page that would render it in this repo.

| Spec template | Legacy name | Visage today | Gap |
|---|---|---|---|
| `SYSTEM_idle` | (homescreen skill `idle`) | `idle_page.dart`, via the homescreen namespace | Spec forbids an app home screen (§6.9). Needs a backend-owned resting page fed by `gui.ambient.*`. |
| `SYSTEM_loading` | `SYSTEM_Loading` | `loading_page.dart` | Alias only. |
| `SYSTEM_status` | `SYSTEM_Status` | `status_page.dart` | Key: legacy `status: "Enabled"`, spec `success: bool`. Model reads `status` (`templates_model.dart` line 87). |
| `SYSTEM_error` | none | none | New page. |
| `SYSTEM_text` | `SYSTEM_TextFrame` | `text_frame_page.dart` | Alias only. |
| `SYSTEM_image` | `SYSTEM_ImageFrame` | `image_frame_page.dart` | Alias. Drop path acceptance on the GUI-1 path (§3.5). |
| `SYSTEM_animated_image` | `SYSTEM_AnimatedImageFrame` | `image_frame_page.dart` | Alias. Same image rule. |
| `SYSTEM_list` | `List.qml` (legacy plugin) | `alert_list_page.dart`, `ocp_list_page.dart` (skill-specific) | New generic page; reuse list widgets. |
| `SYSTEM_grid` | `Grid.qml` | none | New page. |
| `SYSTEM_table` | `Table.qml` | none | New page. Row length must equal `columns`; mismatch is a fault, degrade to list. |
| `SYSTEM_html` | `SYSTEM_HtmlFrame` | `html_frame_page.dart` | Alias. Discouraged; no extension (issue #27). |
| `SYSTEM_url` | `SYSTEM_UrlFrame` | `url_frame_page.dart` | Alias. Discouraged. |
| `SYSTEM_audio_player` | `AudioPlayer.qml` | `now_playing_page.dart` (OCP keys) | New key mapping (ms, `-1` live). |
| `SYSTEM_video_player` | `VideoPlayer.qml` | none | Degrade to still + title (§6.5) first. Real video is a separate decision. |
| `SYSTEM_media_player` | OCP pages; legacy plugin `SYSTEM_ocp_*` | `now_playing_page.dart`, `ocp_list_page.dart`, `ocp_busy_page.dart` | Key set `media_*` vs OPM docstring `ocp_*`. Three views in one template. |
| `SYSTEM_clock` | `Clock.qml` | `time_page.dart` (date-time skill) | Generic version from the device clock. |
| `SYSTEM_timer` | `Timer.qml` | `timer_page.dart` (alerts skill) | `end_time` (Unix s), `count_up`. Multi-timer waits on spec PR #287. |
| `SYSTEM_weather` | `Weather.qml` | `weather_now_page.dart`, `forecast_page.dart` | Map `condition_code` (10 values) to existing icons; `forecast` to the forecast page. |
| `SYSTEM_map` | `Map.qml` | none | New page. Provider choice and offline degrade to label/coords. |
| `SYSTEM_face` | `SYSTEM_Face` | `system_face_page.dart` | Alias. Key `sleeping` matches. |
| `SYSTEM_confirm`, `SYSTEM_select` | `Confirm.qml`, `Select.qml` | none | Reserved. Do not render. Treat as unknown. |
| (non-spec) | `SYSTEM_InputBox` | `input_box_page.dart` | Not in GUI-1. Keep on legacy path only. Finding candidate: a typed-input companion has the same reply-leg gap as `SYSTEM_select`. |

### 3.2 Other surfaces

| Surface | Spec | Today | Gap |
|---|---|---|---|
| Status events | 16 `ovos.*` topics, broadcast (§5.3) | Visage reads `recognizer_loop:*`, `mycroft.skill.handler.*`, `ovos.listener.record.*` and `enclosure.mouth.viseme_list` from the core bus | Attention and face must accept the `ovos.*` set. Visemes change shape: `[code, end_offset]` pairs plus `start` (`audio-out.md` §5.4). Keep both until producers move. |
| Notifications | count only, `gui.ambient.notifications` (§6.9.1) | full popups, stored list, actions over `ovos.notification.*` on the core bus | Spec has no notification template. Keep the core-bus path; it is outside GUI-1. Badge count from ambient when present. |
| Widgets (timer, alarm, media) | none; `SYSTEM_timer` is a template | `WidgetManager` translates `ovos.widgets.*` | Outside GUI-1. Keep on the legacy path; finding candidate if a resting display needs them. |
| Resting data | `gui.ambient.weather`, `gui.ambient.notifications` | `homescreen.data.*`, homescreen skill session data | Resting page reads ambient status events; time from the device clock. |
| Images | `http(s)` or `data:` only (§3.5) | also absolute paths and `~/.cache/ovos_gui` | GUI-1 path rejects paths and reports a fault. Legacy path unchanged. |
| Sessions | `session_id` per client, `"default"` not a wildcard (§5) | none | Config `session_id` (default `"default"`). Typed commands carry it in `context.session`. |
| Connection report | `any_client_connected` (§6.8) | n/a | Adapter implements it; OPM base lacks it. |
| Multiple namespace pages | non-active entries held, not shown (§4.2) | `PagePager` swipes across a skill's pages | Swipe stays a backend choice; it must not emit `gui.page.show`. Finding candidate: how a client asks for another index. |

---

## 4. Work packages

Each package fits one Opus agent in half a day to two days. Packages in a phase may run in
parallel unless a dependency is listed. Every package that touches spec behaviour appends to
`docs/GUI1_FINDINGS.md`.

### Phase 0: Visage groundwork (no upstream dependency)

**P0.1 Bilingual router.** 1 day.
- Goal: one canonical spec name per page. Legacy names and legacy-plugin QML names are aliases.
- Inputs: §3.1 matrix; ovos-gui #117 `ovos_gui/templates.py` `LEGACY_TO_SPEC` (lines 77–86).
- Files: `lib/pages/router.dart`, new `lib/pages/template_names.dart`, `templates_model.dart`.
- Acceptance: `SYSTEM_TextFrame`, `SYSTEM_text` and `Text.qml` reach the same page.
  `statusModel` accepts `success` and the legacy `status`. Every existing fixture still matches
  `expected/`.
- Tests: table test over every alias; replay of `templates_show_all.jsonl` unchanged.
- Not verifiable without live: none.
- Likely findings: none; the alias list is the record.

**P0.2 Conformance matrix as data.** Half a day.
- Goal: `docs/GUI1_CONFORMANCE.md`, generated or checked from code, one row per template and
  per §8.4/§8.5 clause, with status `none | partial | done` and the test that proves it.
- Files: new doc, new `test/conformance_test.dart` that fails when a router entry has no row.
- Acceptance: the test fails if a spec template has no row.

**P0.3 Findings log and process.** Half a day.
- Goal: `docs/GUI1_FINDINGS.md` with the format in section 6, seeded with findings F1–F8 from
  section 7. Update `CLAUDE.md`: its "Never modify OVOS code" rule now means "never modify
  the live install"; upstream PRs from the forks are in scope.
- Acceptance: each seeded row cites a file and line.

**P0.4 GUI-1 fixture format.** Half a day.
- Goal: define `test/fixtures/gui1/*.jsonl` (server frames as in 2.2) and a replay helper.
  Hand-written at first, labelled "written from spec", like `outgoing/`.
- Acceptance: a replay test drives `GuiState`-equivalent state from a GUI-1 fixture.

### Phase 1: unblock the Python side (PRs to OpenVoiceOS from OscillateLabsLLC forks)

**P1.1 Finish OPM #377.** 1–1.5 days. Depends on: nothing.
- Goal: merge dev into `gui` and align the base with the spec as of today.
- Changes: `media_*` keys in the media docstring; §5.3 topic names in the status docstring;
  add `any_client_connected() -> bool` (default `False`, §6.8); `on_idle` stays device-wide;
  remove the `ovos_gui.homescreen` import from the adapter path (move `GUIExtension` concerns
  out or guard them); mark `handle_show_confirm`/`select` reserved.
- Files: `ovos_plugin_manager/templates/gui.py`, `gui.py`, `docs/api/gui-adapter.md`,
  `test/unittests/test_gui.py`.
- Acceptance: unit tests green on dev; a dummy adapter loads through `create_all`; a raising
  adapter is skipped and logged.
- Likely findings: F3 (idle per session or device-wide).

**P1.2 Rebase ovos-gui #117 onto dev and catch up the spec.** 2 days. Depends on: nothing.
- Goal: #117 green on current dev, plus the four spec changes it predates.
- Changes: resolve `pyproject.toml`; `null` removes a key; §3.2 diagnostic (log) for unknown
  `SYSTEM_*` names that does not stop the remaining `page_names`; forward the §5.3 topic table;
  keep the last `gui.ambient.*` message per topic and forward it.
- Files: `ovos_gui/namespace.py`, `ovos_gui/templates.py`, tests.
- Acceptance: the e2e test `test/end2end/test_gui1_service_e2e.py` passes; new unit tests for
  null removal, diagnostic and ambient.
- Not verifiable without live: whether core emits the `ovos.*` topics (section 1.4).
- Likely findings: F5 (legacy status names), F6 (`__idle: null`).

**P1.3 Land #112 on top of P1.2.** 2 days. Depends on: P1.1, P1.2.
- Goal: the adapter-dispatch service with #117's per-session and spec fixes ported in.
- Changes: port, not rebase (section 1.3). `on_session_update` gets the merged map; call
  `on_idle` when the stack empties; `.get("__idle")`; OPM pin `>=3.1.0a1`; decide about the
  `ovos-spec-tools` dependency with Jarbas; keep or drop the resource cache from dev #132 per
  open question Q1.
- Files: `ovos_gui/namespace.py`, `service.py`, `message_types.py`, `pyproject.toml`, tests,
  `docs/adapter-development/CONTRACT.md`.
- Acceptance: unit and e2e green; a recording adapter receives the spec event sequence for a
  scripted producer (section 5).
- Likely findings: F2 (session discovery), F3, F4.

**P1.4 Legacy adapter keeps working.** 1 day. Depends on: P1.1, P1.3.
- Goal: `ovos-legacy-mycroft-gui-plugin` on `session_id`, with the new OPM base. Merge
  `feat/session-id-contract`. Replace `SYSTEM_ocp_*` with `SYSTEM_media_player`. Emit status
  events in the new names to Qt as well.
- Acceptance: Visage in legacy mode against ovos-gui (P1.3) + this plugin shows every page in
  `templates_show_all.jsonl`.
- Not verifiable without live: Qt clients; only Visage legacy mode is tested.

**P1.5 Producer rename (optional, Jarbas's call).** 1 day. Depends on: P1.2 (aliases on the
service side).
- Goal: rebase ovos-bus-client `gui_depr` on dev; emit spec names; `success` instead of
  `status`; omit `__idle` when unset once P1.3 ships.

### Phase 2: `ovos-gui-plugin-visage`

**P2.1 Scaffold.** Half a day. Depends on: Mike creates the repo.
- Goal: Python package, `opm.gui_adapter` entry point `ovos-gui-plugin-visage`, config schema
  (`host`, `port`, `path`), release-please, CI (lint, unit, build), Apache-2.0, STE README.
- Acceptance: `OVOSGUIAdapterFactory.create_all()` from P1.1 finds and builds it.

**P2.2 Websocket server and wire protocol.** 1.5 days. Depends on: P2.1.
- Goal: section 2.2 exactly. Server on a daemon thread; construction returns at once (§6.2).
  Handlers enqueue and return; a sender thread writes frames (§6.6 non-blocking). Every
  handler catches and logs.
- Acceptance: a slow client does not slow `dispatch_template` (measured with a stalled socket).
- Likely findings: none in the spec (transport is ours).

**P2.3 Session routing and snapshot.** 1 day. Depends on: P2.2, P1.3.
- Goal: per-session delivery, `"default"` not a wildcard, status and idle broadcast, snapshot
  from the query surface on `hello`, release per-namespace state on `deactivated`,
  `any_client_connected`.
- Likely findings: F2, F3, F7.

**P2.4 Tests and fixtures.** 1 day. Depends on: P2.3.
- Goal: pytest suite with a fake ovos-gui driving the adapter; record its output as
  `test/fixtures/gui1/*.jsonl` and copy them into Visage (P0.4 format).
- Acceptance: the same fixture files pass in both repos.

**P2.5 Release.** Half a day. Depends on: P2.4. PyPI publish later, after Mike's PyPI setup.

### Phase 3: Visage speaks GUI-1

**P3.1 GUI-1 client and detection.** 1.5 days. Depends on: P0.1, P0.4, P2.2 (or its fixtures).
- Goal: `lib/protocol/gui1_client.dart`, `protocol` config, `auto` probe, a GUI-1 state model
  per session (stack, data, active template), snapshot apply.
- Files: `lib/protocol/`, `lib/state/`, `lib/app_config.dart`, `endpoints_web.dart`,
  `sidecar/default.conf.template`.
- Acceptance: GUI-1 fixtures replay; legacy fixtures unchanged; probe falls back in under 3 s.

**P3.2 Templates A: error, list, grid, table.** 1.5 days. Depends on: P0.1.
**P3.3 Templates B: clock, timer, weather, map.** 2 days. Depends on: P0.1.
- Weather maps `condition_code` to existing icons; forecast reuses `forecast_page.dart`.
- Map: provider and offline behaviour are decisions; degrade to label first.
- Likely findings: F8 (multi-timer, #287).
**P3.4 Templates C: audio, video, media player.** 2 days. Depends on: P0.1.
- Reuse the OCP pages with a `media_*` key model. Video degrades to still + title in v1.
- Likely findings: Q4 (OCP pages vs `SYSTEM_media_player`), transport controls (§7.1 points
  elsewhere).

For each template package: one view model per template (pure, unit tested), one widget test from
a GUI-1 fixture, a golden where the look is new, and a degradation test for missing optional
keys (§6.5).

**P3.5 Backend-owned resting display.** 1.5 days. Depends on: P3.1.
- Goal: on the GUI-1 path the idle page reads the device clock and `gui.ambient.*` status
  events. No homescreen namespace. Legacy path unchanged.
- Likely findings: F4 (what the resting display may show beyond time, weather, count).

**P3.6 Status events and visemes.** 1 day. Depends on: P3.1.
- Goal: `Attention` and the face accept the §5.3 `ovos.*` set and the `audio-out.md` §5.4
  viseme shape, beside the legacy topics.
- Not verifiable without live: real producers of the new topics (section 1.4).

**P3.7 Sessions.** 1 day. Depends on: P3.1, P2.3.
- Goal: config `session_id`; typed commands carry `context.session.session_id`; two Visage
  instances on different sessions see different stacks; same session mirrors.
- Not verifiable without live: whether core answers a non-default session's typed command
  with GUI output to that session (SESSION-2 client authority).

### Phase 4: contribute back and document

- **P4.1 Transfer the adapter** (half a day): to OpenVoiceOS per Q7.
- **P4.2 Spec informative note** (half a day): Visage as reference backend in §9 or the README.
- **P4.3 Visage docs** (1 day): SCOPE.md, README protocol section, sidecar, conformance file.

---

## 5. Test strategy

Mike's daily OVOS (`~/.venvs/ovos`, `~/.venvs/ovos-gui`, bus on 8181, GUI on 18181) is never
touched. No install into those venvs, no connection to that bus.

**Isolated stack.** One script, `tool/gui1_stack.sh` in the adapter repo, builds and runs:

- a venv under the session scratchpad (or a `python:3.11-slim` container);
- `ovos-messagebus` on port **28181**, configured through its own `XDG_CONFIG_HOME`;
- ovos-gui from the P1.3 branch, OPM from P1.1, the adapter from P2, all editable installs;
- the adapter on port **28182**;
- a fake producer (`fake_skill.py`) that walks every template, `gui.value.set` with a `null`,
  `__idle` numbers and `true`, `gui.clear.namespace`, two sessions, ambient topics and the
  §5.3 status topics.

Visage runs against it with `VISAGE_PROTOCOL=gui1` and the bus URL pointed at 28181. A second
Visage instance with another `session_id` proves routing.

**Recorded fixtures.** Follow the existing pattern: record the adapter's frames to
`test/fixtures/gui1/<scenario>.jsonl`, the producer's bus traffic to
`test/fixtures/gui1/corebus/<scenario>.jsonl`, and the expected Visage state to
`test/fixtures/gui1/expected/<scenario>.json`. Hand-written fixtures say so in their first
line, as `outgoing/` does.

**Layers.**

| Layer | Tool | Proves |
|---|---|---|
| OPM base, ovos-gui hub | pytest in each repo | spec clauses §4, §5, §6.3, §8.3 |
| Adapter | pytest with a fake hub and real websockets | §6.2, §6.6, §8.4, wire protocol |
| Visage models and pages | `flutter test` with GUI-1 fixtures | §6.5 degradation, rendering |
| End to end | isolated stack + Visage, by eye, screenshots in the PR | the whole path |

**Not planned:** the Kubuntu test box. It has no sudo and no compositor on `wayland-0`.

---

## 6. Spec findings process

Rule: we do not work around a spec problem. When code and spec disagree, the spec PR goes to
`OpenVoiceOS/architecture` (`dev`) on the same day, and the code follows the proposed text.
If Jarbas rejects it, the code follows the spec and the row records the outcome.

`docs/GUI1_FINDINGS.md` format, one row per finding, newest last:

| ID | Date | Package | Spec says (§, line) | We found (file, line or fixture) | Proposed change | Upstream PR | Outcome |
|---|---|---|---|---|---|---|---|
| F1 | 2026-10-24 | P0.3 | ... | ... | ... | architecture#NNN | open |

- "Spec says" quotes the clause and cites `gui-1.md` with a line range at a commit.
- "We found" cites evidence, not opinion: a test, a fixture, a log line.
- "Outcome" is `open`, `merged`, `rejected` or `superseded by Fn`.
- A finding about OVOS code that the spec already covers is not a spec finding. It goes to that
  repo as an issue or a PR and gets a row only for traceability.

---

## 7. Risks and open questions

### 7.1 Findings to seed the log (P0.3)

| ID | Finding | Evidence |
|---|---|---|
| F1 | #117 and #112 are siblings that conflict in four files. The service work is a port, not a rebase. | section 1.3 |
| F2 | The spec says clients "declare the `session_id` they belong to" (§5.1) but no hub-to-adapter event says which sessions exist or end. An adapter cannot release per-session state when a session ends. | `gui-1.md` lines 499–504; SESSION-2 owns lifecycle |
| F3 | §4.3 returns *a session* to idle when its stack empties (line 477), but the idle hook is device-wide (§6.3 table, line 621) and `on_idle()` has no `session_id` (OPM `templates/gui.py` line 309). A per-session screen cannot tell whose idle it is. | spec lines 477, 621 |
| F4 | `SYSTEM_idle` may not be requested by apps (line 217), but it is in the catalogue and has an adapter handler. Is it a template at all, or only the idle hook? | spec line 217; OPM line 106 |
| F5 | Producer and service still use legacy status names; spec §5.3 lists only `ovos.*`. Nothing in the five cloned repos emits them. | section 1.4 |
| F6 | `__idle: null` is sent on purpose by ovos-bus-client to protect released ovos-gui. Spec §3.3 forbids it. | commit `c0ae994` |
| F7 | §4.2 says non-active `page_names` entries are "held". There is no way for a client to change the index (swipe). Visage's `PagePager` would have no spec path. | spec lines 426–436 |
| F8 | `SYSTEM_timer` holds one timer. Spec PR #287 (multi-timer) is open. | spec line 260 |

### 7.2 Questions for Jarbas

- **Q1.** Does ovos-gui keep building and serving `~/.cache/ovos_gui` (dev #132) once #112 lands?
  Under GUI-1 nothing needs it except legacy QML.
- **Q2.** How does an adapter learn the set of live `session_id`s and when one ends (F2)? Is
  the query surface `get_all_sessions()` enough?
- **Q3.** When does the frame rename (`gui_depr`) land, and does it also rename the `__` keys?
  What are the new key names? Both change Visage's legacy path.
- **Q4.** Does `SYSTEM_media_player` replace the OCP pages (`PlayerLoader`, `Home`,
  `SuggestionsView`) for every client, so OCP stops showing its own pages?
- **Q5.** Multi-session delivery: when core handles an utterance for session X, which GUI
  messages carry X? Are status events still device-wide when two sessions talk at once?
- **Q6.** Is `ovos-spec-tools` a required dependency of ovos-gui?
- **Q7.** Where does the reference adapter live at the end: a new OpenVoiceOS repo, or stays in
  OscillateLabsLLC?
- **Q8.** Should notifications (popups, stored list, actions) become a GUI-1 surface, or stay
  outside it?

### 7.3 Risks

| Risk | Effect | Mitigation |
|---|---|---|
| Upstream review is slow; PRs sit as drafts again. | Phases 1–3 stall at P1.3. | Visage and the adapter test against our fork branches; Phase 0 and P3.2–P3.4 need no upstream. |
| The spec moves while we build. | Rework. | Pin the spec commit in each package; the findings log is the change record. |
| No producer emits the new topics yet. | Face and resting display cannot be proven live. | Fake producer in the isolated stack; keep legacy topics in Visage. |
| Qt shelved but users run ovos-shell. | Those users lose new templates. | P1.4 keeps the legacy adapter honest; not our renderer to finish. |
| Two transports in Visage for a long time. | More code paths. | One state model per protocol behind one router; drop legacy when ovos-gui legacy is gone. |

---

## 8. Effort

| Phase | Packages | Agent-days | Confidence |
|---|---|---|---|
| 0 Visage groundwork | P0.1–P0.4 | 2.5 | high |
| 1 Python service side | P1.1–P1.5 | 7–7.5 | medium: the #112 port is the unknown |
| 2 Adapter plugin | P2.1–P2.5 | 4.5 | medium-high |
| 3 Visage native GUI-1 | P3.1–P3.7 | 10.5 | medium: map and video choices can grow |
| 4 Contribute back | P4.1–P4.3 | 2 | high for the work, low for the timing |
| **Total** | | **~27–28** | medium-low overall; review latency upstream is not counted |

Critical path: P1.1 → P1.3 → P2.3 → P3.1 → P3.7. Phase 0 and the template packages run beside it.

**Mike does these himself:**
create `OscillateLabsLLC/ovos-gui-plugin-visage`; fork `ovos-plugin-manager`, `ovos-gui`,
`ovos-legacy-mycroft-gui-plugin`, `ovos-bus-client` and `architecture` into OscillateLabsLLC;
merge our PRs; ask Jarbas Q1–Q8; set up PyPI for the adapter.
