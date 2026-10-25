# ovos-gui-visage: scope of the Flutter port

A Flutter GUI client for OpenVoiceOS that expands the 2018 Mycroft Mark II Kickstarter
concept beyond the demo. It starts as a port of
[ovos-visage](https://github.com/OscillateLabsLLC/ovos-visage) (Python middle layer plus a
browser page) to one Dart codebase. ovos-visage's `docs/SPEC.md` remains the protocol and
visual reference; this file records what changes in the port and why.

## Decisions (2026-10-17)

| Decision | Choice |
|---|---|
| Targets | macOS first, then Linux and the web. No Windows for now: nobody in the user base runs OVOS on it (decided 2026-10-18; the CI job was removed, the Flutter runner directory stays). No iOS, no Android. |
| Deployment | Same-host display: the app runs on the machine that runs OVOS and reads `~/.cache/ovos_gui` directly. |
| Remote use | The web build, served from a sidecar container on the OVOS host, instead of a phone app. The sidecar proxies the two websockets, so its port is the only one exposed and the place to put authentication and TLS; the bus itself stays off the LAN. |
| Middle layer | None on desktop. The Dart app is the GUI client, the state mirror and the WidgetManager. The web build needs the sidecar (`sidecar/`) to serve the cache, since ovos-gui 1.5.3a1 has no file server. |
| Webviews | `SYSTEM_HtmlFrame` and `SYSTEM_UrlFrame` are gated per platform, best effort: webview_flutter on macOS, an iframe on the web, text fallbacks elsewhere. No Linux webview is required. Kept for legacy compatibility only: upstream (the GUI-1 spec work) recommends against `show_url` / `show_html`, nothing in the OpenVoiceOS org uses them, and they are being deprecated, so the current support stays and is not extended (issue #27). |
| Face | Composed from an eye style, a mouth style and a backdrop that places them; nine eye styles, eight mouth styles, a regular or large mouth (`docs/FACE_PALETTES.md`). `visage` and `mark1` are presets. Chosen by `face` in config or `VISAGE_FACE`, and changed while running from the picker page over the bus (`visage.face.*`) or by hand in try-on mode. |
| Input | Touch and pointer, decided 2026-10-23: Visage lets a user do what the Qt GUI (mycroft-gui-qt5, ovos-shell and the stock skills' QML) let them do by touch or mouse. Pages hold plain controls that answer through the GUI socket; the shell owns every gesture (see Input below). Until then it was display-only, so that the port could reach parity with ovos-visage without a gesture layer in every page; try-on mode and the peek badge's tap were the only input. |
| macOS sandbox | Off. The app opens local sockets and reads the GUI cache; it is a kiosk display, not an App Store app. Signed with the Oscillate Labs LLC team. |
| Linux | Built in CI; each release attaches `.deb` packages for amd64 and arm64, built on Debian Bookworm for glibc 2.36 and install-tested on Debian 12 and Ubuntu 24.04 (`docs/PACKAGING.md`). Checked by hand on Kubuntu 24.04; the workflow pattern comes from neon-node-flutter-app. |

## Architecture

```
ovos-core ──core bus 8181──▶ ovos-gui-service ──GUI ws 18181──▶ ovos-gui-visage (Dart)
skills, homescreen                 ▲ ovos.widgets.* translation       GuiClient, GuiState, WidgetManager
                                   └─ or GUI-1 adapter ──ws 18182/gui1──▶ Gui1Client (Protocols below)
                                                                      pages, face, attention
                                                                      ~/.cache/ovos_gui read directly
```

Two processes besides OVOS: `ovos-gui-service` with the homescreen skill in its own
virtualenv (ovos-visage SPEC 3.1), and this app.

Package layout:

```
lib/
  main.dart            app shell: 480 x 800 frame scaled to the window, page, attention overlay
  json.dart            the Json typedef
  protocol/            core_bus.dart, gui_client.dart (ports of bus.py, gui_client.py)
  state/gui_state.dart namespaces, pages, session data, active stack (port of state.py)
  attention.dart       listen/think/speak state machine (port of attention.js)
  face/                face_theme.dart (contract), visage_theme.dart (current look), face.dart (widget), visemes.dart
  lottie/              segment.dart (liveSegment), cache_lottie.dart (OVOS animations from the cache)
  resources/           locate.dart (pure), platform_io.dart (disk) and platform_web.dart (sidecar routes) behind a conditional export
  protocol/endpoints*  where the sockets are per platform: the host (desktop) or the page's origin (web)
  faults.dart          reportFault: a survivable fault reaches the log before its fallback shows
  widgets/             WidgetManager port, shared circle/ring/glow widgets, icon motion, WebFrame
  pages/               one widget per page plus pure view models
sidecar/               Dockerfile, nginx template and compose file for the web build on the OVOS host
tool/                  split_icons.py, serve_web.py (the web build against a local OVOS, no sidecar)
test/
  fixtures/*.jsonl     the recorded protocol traffic from ovos-visage, unchanged
  fixtures/expected/   the Python reference's state snapshot per fixture; gui_state_test requires a match
```

## Protocols (2026-10-24)

Visage speaks one of two GUI protocols per connection. Both fill the same `GuiState`, so the router, the pages and the
face do not know which one is in use.

| Protocol | Server | Socket | Client code |
|---|---|---|---|
| legacy | ovos-gui 1.x (`mycroft.gui.connected` on the core bus, then the port it names) | `ws://<host>:18181/gui` | `lib/protocol/gui_client.dart`, `GuiState.apply` |
| GUI-1 | `ovos-gui-plugin-visage`, an OVOS-GUI-1 adapter (`gui1-upstream/WIRE.md`, plan section 2.2) | `ws://<host>:18182/gui1` | `lib/protocol/gui1_client.dart`, `lib/state/gui1_apply.dart` |

`lib/protocol/gui_link.dart` chooses. With `auto`, the default, it opens the GUI-1 endpoint before every connection
and sends `hello`. A `welcome` within 3 s selects GUI-1 for that connection. A refused connection, a timeout or an
`error` selects legacy. The choice is logged and the menu shows it ("Protocol: GUI-1" or "Protocol: legacy"). Visage
does not switch while a connection holds; a reconnect probes again. With `gui1`, Visage retries the adapter only. With
`legacy`, `GuiClient` runs as before and nothing probes.

| Config key | Environment | Values | Default |
|---|---|---|---|
| `protocol` | `VISAGE_PROTOCOL` | `auto`, `gui1`, `legacy` | `auto` |
| `gui1Url` | `VISAGE_GUI1_URL` | a `ws://` or `wss://` URL | the bus host, port 18182, path `/gui1`; the sidecar's `/gui1` on the web |
| — | `OVOS_HOST`, `OVOS_PORT` | the core bus host and port (desktop) | `127.0.0.1`, `8181` |

Under GUI-1 a namespace holds exactly one page, named with its spec template (`SYSTEM_text`), and its data is the full
map of the last frame; Visage never merges. `deactivated` drops the namespace, a `snapshot` replaces the stack, and `status` frames drive the face. `idle` is
device-wide, so it empties the screen only when this session's stack is already empty; otherwise it is ignored and logged
once (finding F16). Status topics are keyed by their [gui-1.md 5.3 System-wide signals](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#53-system-wide-signals) `ovos.*` names, with the legacy bus names as aliases
(`lib/status_topics.dart`); a topic Visage does not follow is reported once. An unknown `SYSTEM_` name is reported once and shows the fallback.
GUI-1 has no reply leg, so on GUI-1 Visage puts each page event (controls, focus, interaction) on the core bus itself,
as the message legacy ovos-gui forwarded (finding F14, `test/fixtures/outgoing/gui1_page_events.jsonl`); typed
commands, volume and notification actions use the core bus on both protocols. Fixtures: `test/fixtures/gui1/`, written
from WIRE.md, and `test/fixtures/gui1/recorded/`, recorded from the adapter.

## What ports how

| ovos-visage | ovos-gui-visage | Notes |
|---|---|---|
| `state.py` + `mirror.js` | `GuiState` | One model instead of two; the parity test now compares against Python goldens. |
| `bus.py`, `gui_client.py` | `CoreBus`, `GuiClient` | Verified live: port negotiation, re-announce, boot sync. |
| `widgets.py` | `WidgetManager` | Same translation on the core bus. One app per host, so no double translation. |
| `resources.py`, `web.py` | `lib/resources/` | `locate` classifies a value (data URI, http, `/res/` cache path, absolute path). The desktop reads cache and absolute paths from disk, since the trust boundary (session data from skills) is the same; the web build fetches `/res/` and `/res-abs/` from the sidecar. Conditional exports pick the half; nothing else touches `dart:io`. |
| `framing.py`, `/frameable` | not needed with a webview | A webview loads pages top-level, so sites that refuse framing work (verified with google.com on macOS). The web build's iframe cannot tell a refusal from inside the page, so it shows the browser's own refusal there; the URL chip stays as the fallback where there is no webview. |
| `face.js`, `visemes.js` | `Face`, `FaceTheme`, `visemes.dart` | Same geometry and shapes; Catmull-Rom path in a `CustomPainter`. |
| `attention.js` | `Attention` | Same events and timings. |
| `lottie.js`, vendored lottie-web | `lottie` package | All six platforms. `liveSegment` ported. Fidelity on OVOS's files checked in the spike. |
| `static/icons/*.svg` | Flutter animations | `flutter_svg` does not run embedded CSS keyframes, so each icon is a static SVG part plus a Flutter animation. |
| `pages/*.js`, `*_model.js` | `pages/*.dart` | View models stay pure and tested; `textFrame` pagination measures with `TextPainter`. |
| CSS polish vocabulary | shared widgets | glow, gradient fill, stagger enter, bloom as reusable widgets; a theme file holds the colour tokens. |
| `tests/test_style_rules.py` | golden tests plus a token check | No cards, no accent borders: enforced by review of goldens and by keeping fills to circles in the shared widgets. |

## Template names

Template pages are keyed by their OVOS-GUI-1 name (gui-1.md section 3); `lib/pages/template_names.dart` holds the
vocabulary and the aliases, and nothing else names an alias. ovos-bus-client's frame names and the QML files that
ovos-legacy-mycroft-gui-plugin shows reach the same page as the spec name:

| Spec name | Aliases | Page |
|---|---|---|
| `SYSTEM_text` | `SYSTEM_TextFrame`, `Text.qml` | text frame |
| `SYSTEM_image` | `SYSTEM_ImageFrame`, `Image.qml` | image frame |
| `SYSTEM_animated_image` | `SYSTEM_AnimatedImageFrame`, `AnimatedImage.qml` | image frame |
| `SYSTEM_status` | `SYSTEM_Status`, `Status.qml` | status (`success: bool`, or legacy `status: "Enabled"`) |
| `SYSTEM_loading` | `SYSTEM_Loading`, `Loading.qml` | loading |
| `SYSTEM_face` | `SYSTEM_Face`, `Face.qml` | face |
| `SYSTEM_html` | `SYSTEM_HtmlFrame`, `Html.qml` | html frame |
| `SYSTEM_url` | `SYSTEM_UrlFrame`, `Url.qml` | url frame |

`SYSTEM_idle`, `SYSTEM_error`, `SYSTEM_list`, `SYSTEM_grid`, `SYSTEM_table`, `SYSTEM_audio_player`,
`SYSTEM_video_player`, `SYSTEM_media_player`, `SYSTEM_clock`, `SYSTEM_timer`, `SYSTEM_weather` and `SYSTEM_map` (and
their `.qml` names) have no page yet: they show the fallback and report a fault once per template. `SYSTEM_confirm`
and `SYSTEM_select` are reserved by the spec and route as unknown pages. `SYSTEM_InputBox` is not in GUI-1 and keeps
its legacy name only. An exact skill route still wins over a template name.

## Platform gating

| Capability | macOS | Linux | web |
|---|---|---|---|
| Core bus and GUI socket | yes | yes | through the sidecar's `/core` and `/gui` proxies, or `?bus=ws://host:8181` straight to OVOS |
| Read `~/.cache/ovos_gui` | yes | yes | no, via sidecar `/res/` and `/res-abs/` |
| `SYSTEM_HtmlFrame` with scripts | WKWebView | no (plain text) | iframe |
| `SYSTEM_UrlFrame` | WKWebView | URL chip | iframe; a refused site shows the browser's refusal |
| Lottie | yes | yes | yes |

## Phases

0. **Spike** (done): protocol clients, state parity, the face with recorded visemes, OVOS
   Lottie playback, all against the live stack on macOS.
1. **Core shell** (done): router, idle page, date-time pages, text/face/loading/status/image
   templates, WidgetManager, offline pill, reconnect.
2. **Weather and alerts pages** (done). Icons move part by part as their SVGs did:
   `tool/split_icons.py` cuts each source icon into z-ordered layer assets and generates
   `lib/widgets/icon_layers.g.dart`; `lib/widgets/motion.dart` evaluates CSS-style
   per-property keyframe tracks (curve per interval, delays, alternate directions);
   `lib/widgets/icon_motion.dart` transcribes every stylesheet. The globe's meridians and the
   reminder's ticks animate shape, not transform, so `lib/widgets/icon_painters.dart` paints
   them. Rerun the splitter after editing anything in `assets/icon_sources/`.
3. **OCP pages** (done): now playing, busy, suggestions, home. Verified by replaying the
   recorded OCP session data through ovos-gui with `gui.value.set` / `gui.page.show`, since
   OCP need not be installed to test the pages.
4. **Webviews and the web build** (done). `WebFrame` exists where webview_flutter has a
   registered implementation (WKWebView on macOS, an iframe on the web) and the pages keep
   their text fallbacks elsewhere.
   The resource layer and the socket endpoints are split per platform behind conditional
   exports, so the web build compiles and was verified in Chrome against the local OVOS with
   `tool/serve_web.py`. `sidecar/` serves the build, the cache and proxies both websockets;
   CI builds the image and checks the rendered nginx config, since no Docker daemon was
   available locally.
5. **CI, packaging, release-please** (built; waits on the owner's Apple and GitHub setup). CI builds
   macOS, Linux, the web and the sidecar image; release-please tags `v<version>`. macOS ships
   outside the App Store as a Developer ID app with the hardened runtime, notarised, through a cask
   in `OscillateLabsLLC/homebrew-tap` (`docs/PACKAGING.md`): `tool/release_macos.sh` builds, signs,
   notarises and zips, and `.github/workflows/release.yml` runs it on each release, uploads the zip
   and checksum and bumps the cask. Verified locally with an ad hoc signature only. The first
   signed release waits on the Developer ID certificate, the App Store Connect API key, the two
   GitHub repositories and their secrets. Linux ships as `.deb` packages for amd64 and arm64 on
   each release (`tool/package_deb.sh`, `.github/workflows/linux_deb.yml`, issue #17). Not
   published yet: the sidecar image.
6. **Widget modes** (done on macOS; `desktop` is the default): `lib/window/` reads `~/.config/ovos-gui-visage/config.json`
   (environment on top) and places a frameless window in a corner of the primary display's
   work area, beneath everything (`desktop`) or above (`float`), on every Space, through
   `window_manager` and `screen_retriever`. The window background goes transparent so the
   rounded frame floats. Nothing in the pages changes, since the frame already scales to the
   window. Verified on Kubuntu 24.04 (X11, KWin) on 2026-10-18: every mode places correctly;
   `desktop` uses the window manager's keep-below since there is no runner level; the two
   window_manager calls Linux lacks (shadow, all workspaces) are reported once and skipped; GTK
   applies a resize at its next layout pass, so a collapse waits for the new size before it
   moves; and a non-resizable GTK window keeps its default size, so Linux windows stay
   resizable. Wayland does not let apps position their own windows, so the Linux runner prefers X11 through Xwayland and native Wayland only reports that the corner modes cannot be placed (issue #13); the web
   build has no window to move. Why not WidgetKit:
   a widget extension gets no sockets and a refresh budget of a few timeline reloads an hour,
   so it could only show slow-changing information from the main app. Peek mode (`window.peek`)
   keeps a widget as a small round badge of the resting face in its corner and grows the window
   only while OVOS listens, thinks or speaks (`lib/window/peek.dart`), switchable over the bus
   with `visage.window.set`. On macOS a widget is an accessory app with a menu bar item
   (`lib/window/status_menu.dart`, `macos/Runner/StatusMenu.swift`) that shows or hides it, toggles
   peek, switches between `float` and `desktop`, and picks the face and colourway. Kiosk mode
   (`kiosk`) fills the primary display one level below the menu bar, above the Dock and notifications,
   with the Dock hidden and the menu bar auto-hidden while the app is in front, a power assertion that
   keeps the display awake (on Linux an `org.freedesktop.ScreenSaver` idle inhibit over the session bus,
   or the desktop portal's, `lib/window/idle_inhibit*.dart`), and a pointer that hides after 5 s (`lib/window/kiosk_*.dart`,
   `macos/Runner/Kiosk.swift`). Escape, the menu's Full screen or `visage.window.set` leaves it for the
   previous mode; it is not native fullscreen, which makes its own Space and animates.

7. **Face themes** (done): `lib/face/themes.dart` maps a configured name to a theme. The Mark 1
   theme (`mark1_theme.dart`) draws the faceplate glass, the eye rings with the firmware's
   narrow and blink pixel order, and the mouth matrix from `mark1_images.g.dart`, which
   `tool/port_mark1_images.py` generates from ovos-virtual-mark1's firmware tables (listen,
   talk, think and viseme frames with their step times). The frame now carries the current
   viseme code and a compact flag, so a theme whose full layout does not fit the badge disc can
   stack itself.
8. **Face palettes and switching** (done): themes became compositions. A backdrop (bare screen or
   the Mark 1 plate) hands slots to an eye style and a mouth style (`lib/face/styles/`), named in
   `styles.dart` and chosen by a `FaceSpec`; `visage` and `mark1` are presets, held to goldens.
   `FaceRemote` applies `visage.face.set` from the bus, answers `visage.face.get`, announces
   `visage.face.state` and writes the face back to the config file; `docs/face-palettes.html`
   is both the design preview and, served by the sidecar or opened with `?bus=`, the picker that
   drives the device. Try-on mode (`try_on.dart`) is the first gesture surface: long-press,
   swipe to cycle, swipe the mouth vertically for size, tap to keep.
9. **Input** (2026-10-23): pages answer back (Input above). The in-window menu (#14), typed commands,
   SYSTEM_InputBox answers and page swipes come first; skill controls (OCP transport, alerts, notifications)
   follow on top.

## Input (2026-10-23)

Pages answer the way Qt pages did: a control calls `PageContext.trigger(event, parameters)`, which sends
`mycroft.events.triggered` on the GUI socket in the page's namespace (`lib/protocol/gui_events.dart`), and
ovos-gui (bus.py `on_message`) emits `<namespace>.<event>` on the core bus. Two event names are ovos-gui's own:
`page_gained_focus` becomes `gui.page_gained_focus` (ovos-gui focuses the page and echoes the event to every
client) and `system.gui.user.interaction`, sent in the `system` namespace, becomes `gui.page_interaction` (it
restarts the namespace's removal timer). Typed commands go straight onto the core bus as `recognizer_loop:utterance`.
Every outgoing shape has a recorded fixture in `test/fixtures/outgoing/`.

Pages never read raw pointers or keys. The shell owns the gestures, and they mean the same in every mode where they
apply:

| Gesture | window | float / desktop, expanded | float / desktop, collapsed badge | kiosk |
|---|---|---|---|---|
| Click or tap a control in a page | activates it | activates it | (no page shows) | activates it |
| Click or tap the badge | | | expands for 10 s | |
| Drag on empty surface | nothing | moves the widget; it snaps to the nearest corner | moves the widget | nothing |
| Clearly horizontal drag (2:1) on a skill with 2+ pages | next or previous page | next or previous page | | next or previous page |
| Left and right arrow keys | next or previous page | next or previous page | | next or previous page |
| Volume up, down and mute keys, where the desktop passes them on | volume up, down, mute toggle | the same | the same | the same |
| Chevrons in the bottom corners | | | | next or previous page |
| Long press | try-on mode | try-on mode | | try-on mode |
| Right-click, two-finger tap, Menu key | opens the menu | opens the menu | expands, then opens the menu | opens the menu |
| Keyboard button on the homescreen | opens the command box | | | opens the command box |
| Escape | closes the menu or command box | the same | | the same, else leaves kiosk |
| Click or tap the notification count on the homescreen | opens the stored notification list | the same | | the same |
| In the notification list: arrow keys, Enter or Space, Escape | move between its buttons, press one, close the list (before Escape does anything else) | the same | | the same |

A press anywhere on a page also sends `system.gui.user.interaction`, as the Qt delegate did. The menu is the one
`lib/window/status_menu.dart` builds for the macOS menu bar item and the Linux tray, drawn a third time with
Flutter's MenuAnchor (`lib/window/window_menu.dart`), without "Hide face" (hiding the window from inside it would
strand a desktop with no menu bar item or tray) and, in a browser, without "Quit". A peeking widget stays
expanded while the menu or the command box is up.

Volume (2026-10-23, `lib/volume.dart`, `lib/volume_controls.dart`): Visage never touches an audio device. The menu's
Volume submenu and the volume keys send `mycroft.volume.increase`, `.decrease` and `.mute.toggle` with no data, which
both PHAL volume plugins handle with their own step; `mycroft.volume.set` is never sent, since ovos-PHAL-plugin-alsa,
ovos-skill-volume and ovos-shell send `percent` as a fraction and ovos-phal-plugin-mac reads it as a whole percent
(a voice "set volume to 50 percent" set the Mac to 0, measured). That is also why the display has no slider. The
level comes from `mycroft.volume.get.response`: ALSA broadcasts one after every change, the Mac plugin only answers,
so a Mac `set.confirm` or `mute.confirm` makes Visage ask. A brief row of dots in the status row shows each change
(`lib/widgets/volume_indicator.dart`) and holds a peeking widget open while it shows.

## Verifying a change

Same rule as ovos-visage SPEC 11: a green test run proves the state machine and view
models; a visible change needs the stack running and eyes on the screen. The drivers in
ovos-visage (`docs/spike_say.py`, `tests/manual/demo.py`, `show_templates.py`,
`replay_visemes.py`) drive this app unchanged, since they only talk to the bus.
