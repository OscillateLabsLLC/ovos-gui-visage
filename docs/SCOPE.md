# ovos-gui-visage: scope of the Flutter port

A Flutter GUI client for OpenVoiceOS that expands the 2018 Mycroft Mark II Kickstarter
concept beyond the demo. It starts as a port of
[ovos-visage](https://github.com/OscillateLabsLLC/ovos-visage) (Python middle layer plus a
browser page) to one Dart codebase. ovos-visage's `docs/SPEC.md` remains the protocol and
visual reference; this file records what changes in the port and why.

## Decisions (2026-10-17)

| Decision | Choice |
|---|---|
| Targets | macOS first, then Linux, Windows, web. No iOS, no Android. |
| Deployment | Same-host display: the app runs on the machine that runs OVOS and reads `~/.cache/ovos_gui` directly. |
| Remote use | The web build, served from a sidecar container on the OVOS host, instead of a phone app. This keeps the unauthenticated core bus off the LAN. |
| Middle layer | None on desktop. The Dart app is the GUI client, the state mirror and the WidgetManager. The web build needs a sidecar to serve the cache (ovos-gui 1.5.3a1 has no file server). |
| Webviews | `SYSTEM_HtmlFrame` and `SYSTEM_UrlFrame` are gated per platform, best effort. No Linux webview is required. |
| Face | Themeable: eyes and mouth are swappable painters behind `FaceTheme`. First pass ships only the current visage look; no new themes. |
| Input | Display-only, as before. Touch is additive later; pages are plain widgets with no gesture plumbing. |
| macOS sandbox | Off. The app opens local sockets and reads the GUI cache; it is a kiosk display, not an App Store app. Signed with the Oscillate Labs LLC team. |
| Linux, Windows | Built and tested in CI only until a desktop is available; the workflow pattern comes from neon-node-flutter-app. |

## Architecture

```
ovos-core ──core bus 8181──▶ ovos-gui-service ──GUI ws 18181──▶ ovos-gui-visage (Dart)
skills, homescreen                 ▲ ovos.widgets.* translation       GuiClient, GuiState, WidgetManager
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
  widgets/             WidgetManager port (to do)
  pages/               one widget per page plus pure view models (to do)
test/
  fixtures/*.jsonl     the recorded protocol traffic from ovos-visage, unchanged
  fixtures/expected/   the Python reference's state snapshot per fixture; gui_state_test requires a match
```

## What ports how

| ovos-visage | ovos-gui-visage | Notes |
|---|---|---|
| `state.py` + `mirror.js` | `GuiState` | One model instead of two; the parity test now compares against Python goldens. |
| `bus.py`, `gui_client.py` | `CoreBus`, `GuiClient` | Verified live: port negotiation, re-announce, boot sync. |
| `widgets.py` | `WidgetManager` | Same translation on the core bus. One app per host, so no double translation. |
| `resources.py`, `web.py` | direct file reads | Session paths under the cache become `File`s; OCP's absolute image paths are read directly, since the trust boundary (session data from skills) is the same. The web build keeps the `/res/` and `/res-abs/` URL scheme via the sidecar. |
| `framing.py`, `/frameable` | not needed with a webview | A webview loads pages top-level, so sites that refuse framing work. The refused-site chip stays as the fallback where there is no webview. |
| `face.js`, `visemes.js` | `Face`, `FaceTheme`, `visemes.dart` | Same geometry and shapes; Catmull-Rom path in a `CustomPainter`. |
| `attention.js` | `Attention` | Same events and timings. |
| `lottie.js`, vendored lottie-web | `lottie` package | All six platforms. `liveSegment` ported. Fidelity on OVOS's files checked in the spike. |
| `static/icons/*.svg` | Flutter animations | `flutter_svg` does not run embedded CSS keyframes, so each icon is a static SVG part plus a Flutter animation. |
| `pages/*.js`, `*_model.js` | `pages/*.dart` | View models stay pure and tested; `textFrame` pagination measures with `TextPainter`. |
| CSS polish vocabulary | shared widgets | glow, gradient fill, stagger enter, bloom as reusable widgets; a theme file holds the colour tokens. |
| `tests/test_style_rules.py` | golden tests plus a token check | No cards, no accent borders: enforced by review of goldens and by keeping fills to circles in the shared widgets. |

## Platform gating

| Capability | macOS | Linux | Windows | web |
|---|---|---|---|---|
| Core bus and GUI socket | yes | yes | yes | yes (same origin or CORS-free websocket) |
| Read `~/.cache/ovos_gui` | yes | yes | yes | no, via sidecar `/res/` |
| `SYSTEM_HtmlFrame` with scripts | webview | no (styled text) | webview | iframe |
| `SYSTEM_UrlFrame` | webview | URL chip | webview | iframe, refused sites show the chip |
| Lottie | yes | yes | yes | yes |

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
4. Webviews with platform gating; the web build and its sidecar. The web build does not
   compile yet: `lib/resources.dart` and `lib/lottie/cache_lottie.dart` read files with
   `dart:io`, so the resource layer needs a web implementation that fetches the sidecar's
   `/res/` URLs instead (conditional imports).
5. CI matrix (macOS, Linux, Windows, web), packaging, release-please.
6. Floating widget mode (later, about a day): a frameless always-on-top window that snaps
   to a screen corner, via `window_manager` plus the display bounds. Works on macOS,
   Windows and X11; Wayland does not let apps position their own windows, and the web
   build has no window to move. Nothing in the pages changes, since the frame already
   scales to the window.

## Verifying a change

Same rule as ovos-visage SPEC 11: a green test run proves the state machine and view
models; a visible change needs the stack running and eyes on the screen. The drivers in
ovos-visage (`docs/spike_say.py`, `tests/manual/demo.py`, `show_templates.py`,
`replay_visemes.py`) drive this app unchanged, since they only talk to the bus.
