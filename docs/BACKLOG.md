# Backlog

Feedback and ideas to take up after parity with ovos-visage. Each entry says where it came from and what
evidence is needed before it is built. Scope phases 5 and 6 (`SCOPE.md`) stay ahead of these.

## From a community user running ovos-visage on a Mac (2026-10-18)

1. **Weather shows NaN in Celsius.** Done: the user is in the Netherlands, a comma-decimal locale.
   Both clients now parse `"21,5"` (ovos-visage branch `fix/comma-decimals`; the wind line was the
   unguarded `Number()` that rendered NaN).
2. **No duration for OCP YouTube tracks.** Done, from source and recordings rather than the user's
   magnitude heuristic: the yt-dlp extractor reports `duration` in seconds and ovos-utils' MediaEntry
   drops that key, so OCP sends `duration` 0 and the page read the track as live forever. mpv still
   reports the real length with every seek-bar position, so with no declared duration a length that
   holds across reports becomes the total (ovos-visage branch `fix/ocp-length-total`). A real YouTube
   recording was not possible on the development stack: yt-dlp now lists only split audio and video
   formats and the plugin asks for a merged `best`, and ovos-audio's mpv plugin raises on every play;
   both are upstream or environment matters, noted in Engram.
3. **Viseme-capable TTS plugin.** The face's mouth needs `enclosure.mouth.viseme_list`; without a TTS
   plugin that emits it the mouth stays still. Out of this repo's scope, but the README should say
   which plugins send visemes.
4. **Mark 1 face as a second theme.** Done: `mark1` draws the faceplate from the firmware's own
   bitmaps and timings (via ovos-virtual-mark1), with the stacked compact badge. Not emulated: eye
   colour and brightness commands, look/spin animations, text and icons on the mouth, since the
   GUI client sees attention events rather than enclosure commands.
5. **Face customisation, switchable in the app on demand.** Done: nine eye styles and eight mouth
   styles that pair freely with a regular or large mouth (`FACE_PALETTES.md`), chosen in config,
   from the picker page over the bus, or by hand on the screen in try-on mode. Colour is done too:
   six colourways or your own tokens in the `colours` field, on the picker page and over the bus
   (no try-on gesture for it yet). Still open: a voice skill that maps
   phrases to `visage.face.set`, and pinch-to-size on touch screens (a vertical swipe sizes the
   mouth for now).
6. **Run on a real Mark II.** Linux build on the Mark II's hardware, fullscreen on the framebuffer or
   under a minimal compositor. Nothing is benchmarked; memory and GPU are the open questions.
7. **Widget and fullscreen modes.** The user pins the browser page beneath the desktop. A WidgetKit
   widget cannot hold a websocket or animate, so the native answer is SCOPE phase 6 (frameless,
   always-on-top, corner-snapping window) plus a fullscreen kiosk mode. Done: the corner widget
   (SCOPE phase 6) and peek mode, which collapses it to a badge until OVOS has attention. Done too:
   the macOS menu bar item, which shows and hides the widget, switches peek and mode, and picks the
   face and colourway without a bus client, and opens the picker page connected to the bus (Face
   picker…, or `visage.face.picker` from a voice skill). Done too: the fullscreen kiosk mode
   (`window.mode: kiosk`, SCOPE phase 6).

## Packaging (2026-10-18)

- The first signed, notarised release needs the owner's one-time setup (`PACKAGING.md`). The
  Release workflow and the Gatekeeper check have never run with a real certificate; check the first
  run end to end, then run `brew audit --cask --online` when the release URL exists.
- Linux has a CI build but no release artifact; the sidecar image is built but not published to a
  registry. Windows is dropped for now (2026-10-18): nobody in the user base runs OVOS on it.

## Carried over

- The picker page (`docs/face-palettes.html`) has no automated interaction test: arrow keys,
  Space/Enter, "Saved", Undo and the reduced-motion stills were built to spec but checked only by
  screenshot, Lighthouse and axe; a small headless test of those would hold them.

- The web iframe cannot detect a site that refuses framing; a `/frameable` check in the sidecar
  would need more than nginx.
- A Dart recorder for protocol fixtures, so contributors do not need ovos-visage's `--record`.
- The `/res-abs/` route in the sidecar serves whatever is mounted under `/srv/host`; ovos-visage
  only served paths that had appeared in session data. Mount narrowly until the sidecar checks.
