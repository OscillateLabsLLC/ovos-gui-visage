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
5. **Face customisation, switchable in the app on demand.** Half done: `face` in the config file or
   `VISAGE_FACE` picks the theme at start. Still to do: switching while running (a key or a bus
   message), and a parameterised visage look (eye colour, ring weight, mouth colour).
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
