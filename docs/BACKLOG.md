# Backlog

Feedback and ideas to take up after parity with ovos-visage. Each entry says where it came from and what
evidence is needed before it is built. Scope phases 5 and 6 (`SCOPE.md`) stay ahead of these.

## From a community user running ovos-visage on a Mac (2026-10-18)

1. **Weather shows NaN in Celsius.** ovos-visage was tested in Celsius, so the unit is not the cause.
   Hypothesis: a locale that formats decimals with a comma (`"21,5"`), which `Number()` in the browser
   turns into NaN. The Dart port parses with `double.tryParse`, which also fails on a comma and would
   show the blank fallback instead. Needs the user's recorded session data (`ovos-visage --record`)
   to confirm before changing either client; the fix is a locale-aware number parse in the weather
   model, with the recorded value as a fixture.
2. **No duration for OCP YouTube tracks.** The user's patch to `trackModel()` treats any `duration`
   under 10000 as seconds and falls back to `length`. That is a heuristic with two holes: a real
   track under ten seconds is multiplied by 1000, and a live stream with a `length` is no longer
   caught by the `duration == 0` check (`lib/pages/ocp_model.dart` documents both units as measured).
   The right fix starts from what the YouTube stream plugin actually sends: record a YouTube
   session, add it as a fixture, and normalise by source, not by magnitude.
3. **Viseme-capable TTS plugin.** The face's mouth needs `enclosure.mouth.viseme_list`; without a TTS
   plugin that emits it the mouth stays still. Out of this repo's scope, but the README should say
   which plugins send visemes.
4. **Mark 1 face as a second theme.** Mike: not planned; the Mark 1 has a virtual Arduino in the loop.
   The `FaceTheme` contract makes a Mark 1 look a theme, but the eyes-as-LED-matrix behaviour is a
   different animation model. Park until face customisation (next) exists.
5. **Face customisation, switchable in the app on demand.** Mike's first planned feature after parity:
   a theme picker over `FaceTheme`, persisted, with the visage look as the default.
6. **Run on a real Mark II.** Linux build on the Mark II's hardware, fullscreen on the framebuffer or
   under a minimal compositor. Nothing is benchmarked; memory and GPU are the open questions.
7. **Widget and fullscreen modes.** The user pins the browser page beneath the desktop. A WidgetKit
   widget cannot hold a websocket or animate, so the native answer is SCOPE phase 6 (frameless,
   always-on-top, corner-snapping window) plus a fullscreen kiosk mode.

## Carried over

- Windows web view once a maintained WebView2 package exists (SCOPE phase 4).
- The web iframe cannot detect a site that refuses framing; a `/frameable` check in the sidecar
  would need more than nginx.
- A Dart recorder for protocol fixtures, so contributors do not need ovos-visage's `--record`.
- The `/res-abs/` route in the sidecar serves whatever is mounted under `/srv/host`; ovos-visage
  only served paths that had appeared in session data. Mount narrowly until the sidecar checks.
