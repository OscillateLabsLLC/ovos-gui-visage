# ovos-gui-visage

[![Status: Proof of Concept](https://img.shields.io/badge/status-proof%20of%20concept-orange)](https://github.com/OscillateLabsLLC/.github/blob/main/SUPPORT_STATUS.md)
[![Unit Tests](https://github.com/OscillateLabsLLC/ovos-gui-visage/actions/workflows/unit_tests.yml/badge.svg)](https://github.com/OscillateLabsLLC/ovos-gui-visage/actions/workflows/unit_tests.yml)

<p align="center">
  <img src="docs/screenshots/templates/text-short-speaking.png" alt="A short answer in a ring chip with the face speaking in a badge at the bottom" width="360">
  <img src="docs/screenshots/ocp/now-playing-live-stream.png" alt="Now playing: a turning station logo inside the progress ring" width="360">
</p>

A Flutter GUI client for [OpenVoiceOS](https://openvoiceos.org) that expands the 2018
Mycroft Mark II Kickstarter concept: a tall portrait screen, big circular widgets, and a
face that listens, thinks and speaks with a viseme-driven mouth. It is the native port of
[ovos-visage](https://github.com/OscillateLabsLLC/ovos-visage), built for macOS first, then
Linux, Windows and the web. It connects to a stock `ovos-gui` service as a GUI client, so no
OVOS code is modified, and renders the homescreen, the system templates, and the weather,
date-time, alerts and OCP media pages. Any other skill page shows as a debug card.

```
ovos-core ──core bus 8181──▶ ovos-gui-service ──GUI ws 18181──▶ ovos-gui-visage (this app)
skills, homescreen                 ▲ ovos.widgets.* translation       reads ~/.cache/ovos_gui directly
```

## Requirements

- A running OVOS install on the same machine (core bus on `ws://127.0.0.1:8181/core`).
- `ovos-gui` and `ovos-skill-homescreen` in their own virtualenv, as ovos-visage's
  `docs/SPEC.md` section 3.1 describes.
- Flutter 3.47 or newer to build; Docker to build the sidecar image.

## Running

```bash
<gui-venv>/bin/ovos-gui-service
<gui-venv>/bin/ovos-skill-launcher ovos-skill-homescreen.openvoiceos
VISAGE_MODE=window flutter run -d macos     # or `just run`; without the variable it starts as a desktop widget
```

The window shows the 480 × 800 screen scaled to fit. To try it without a microphone, inject
an utterance on the core bus with ovos-visage's `docs/spike_say.py "what time is it"`, or run
its `tests/manual/demo.py` tour; both only talk to the bus, so they drive this app unchanged.

## How it works

- **Seam.** `lib/protocol/` announces `framework: html` on the core bus, gets the port, opens
  the GUI socket and announces again (ovos-visage SPEC 5.1).
- **State.** `lib/state/gui_state.dart` mirrors namespaces, pages, session data and the
  active-skill stack. The recorded fixtures from ovos-visage replay to the same snapshots as
  its Python reference (`test/fixtures/expected`).
- **Widgets.** `lib/widgets/widget_manager.dart` plays the shell companion's role for the
  alerts skill's `ovos.widgets.*` messages.
- **Resources.** Session values that are image paths are read straight from
  `~/.cache/ovos_gui` or wherever the skill put them; no file server. The web build fetches
  the same paths from the sidecar instead (`lib/resources/`).
- **Web views.** `SYSTEM_UrlFrame` and `SYSTEM_HtmlFrame` open a web view where the platform
  has one (macOS, and an iframe on the web); elsewhere they show the URL or the page's text.
- **Faults.** Anything the display survives by showing a fallback is reported through
  `lib/faults.dart` first, so a missing animation or image is in the log, never silent.
- **Pages.** One widget per page, routed by `namespace/page` (system templates by page name),
  with pure view models under `flutter test`. Circles, rings and plain text on black; no cards.
- **Face.** `lib/face/` draws the face through a `FaceTheme`: the eyes and the mouth are
  separate painters, so a new look is a new theme. The mouth tweens between seven viseme
  outlines timed by `enclosure.mouth.viseme_list`.

`docs/SCOPE.md` records the port's decisions, the platform gating and the phases; `docs/BACKLOG.md`
holds feedback and ideas queued behind them.
ovos-visage's `docs/SPEC.md` remains the protocol and visual reference.

## As a desktop widget

By default the app is a desktop widget: a frameless window in the top-right corner, 400 px
tall, beneath every other window and above the wallpaper, on every Space. `float` keeps the
same window above everything instead, and `window` is an ordinary window. Configure it in
`~/.config/ovos-gui-visage/config.json`:

```json
{"window": {"mode": "desktop", "corner": "top-right", "height": 400, "margin": 16}}
```

`VISAGE_MODE`, `VISAGE_CORNER`, `VISAGE_HEIGHT` and `VISAGE_MARGIN` override the file, so a
launcher script can pick the mode. Corners are `top-left`, `top-right`, `bottom-left`,
`bottom-right`; the height is in logical pixels and the width follows the 480 × 800 frame. This
is a real window with the live sockets and animations, which a WidgetKit widget cannot have:
widget extensions get no sockets and only a handful of timeline refreshes an hour.

## Web build and sidecar

For a display on another machine, the web build runs in a browser served by a sidecar on the
OVOS host. The sidecar serves the app, the GUI cache under `/res/`, the host's files under
`/res-abs/`, and proxies the two websockets, so port 8080 is the only one to expose. Anyone
who reaches it can drive the OVOS bus through the proxy: keep it on a trusted network, or put
authentication and TLS in front of it.

```bash
docker compose -f sidecar/compose.yaml up --build   # on the OVOS host, then open http://<host>:8080/
```

To try the web build against a local OVOS without the sidecar:

```bash
flutter build web --release
python3 tool/serve_web.py          # http://127.0.0.1:8099/?bus=ws://127.0.0.1:8181
```

## Development

```bash
just test      # flutter test
just lint      # dart format check + flutter analyze
just run       # flutter run -d macos
```

See `CONTRIBUTING.md`.

## License

Apache 2.0
