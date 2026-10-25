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
   GUI client sees attention events rather than enclosure commands. Done too (2026-10-18): the Mark 1
   face was almost invisible as the 96 px peek badge (dim grey rings, a blank mouth); the badge now
   draws larger, bright ring lights and a short resting bar, and the full-size face is unchanged.
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

## Linux desktop (2026-10-18, from a Kubuntu 24.04 laptop)

- **Drag to move the widget.** Done: a drag hands the window to the window manager, and when it stops the
  widget snaps to the nearest corner, which is saved. No drag starts while try-on mode is active.
- **Menu without a tray.** Done (2026-10-23, issue #14): a right-click, a two-finger tap or the Menu key opens the
  same menu inside the window on every platform, the web build too, so stock GNOME and a Pi can change mode, leave
  kiosk and quit without the bus.
- **A tray item.** Done: an app indicator (tray_manager 0.5.3, libayatana-appindicator) with the same menu
  as the macOS item and the resting badge as its icon. tray_manager 0.8 was tried first; its
  StatusNotifierItem published no menu on Plasma.
- **Launcher, icon and start on login.** Done (2026-10-23): hicolor icons from the badge golden
  (`test/linux_icon_test.dart`), `linux/net.oscillatelabs.ovosGuiVisage.desktop`, and an optional XDG
  autostart entry for kiosk. The `.deb` installs the launcher and icons (#17); `tool/linux_desktop.sh` installs them
  per user for a source build, and its kiosk autostart points at `/usr/bin/ovos-gui-visage` when the package is there.
  Checked on Plasma 5.27 only; GNOME and Raspberry Pi OS are untested.
- **Kiosk extras.** Keeping the display awake: done (2026-10-23, issue #15). Kiosk takes an
  `org.freedesktop.ScreenSaver` idle inhibit over the session bus (package:dbus), falls back to
  `org.freedesktop.portal.Inhibit`, and releases it on leaving kiosk and on quit; Plasma lists it in
  PowerDevil's `ListInhibitions`. Not checked on GNOME or labwc; wlroots compositors may need the
  `zwp_idle_inhibit_manager_v1` Wayland protocol instead (issue #20). Leaving kiosk without a flash:
  done (issue #16). KWin gives the window back at its pre-fullscreen frame, GTK's 1280 x 720 default in
  the middle when the app started in kiosk; the widget is now hidden across the switch, placed, shown,
  and placed again (KWin maps a re-shown window at 0,0 when it last sat in that corner). Measured at
  30 fps on a headless KWin: 27 frames in the wrong place before, none after.
- **Wayland.** The runner prefers X11 (`gdk_set_allowed_backends("x11,wayland")`), so a Wayland session with
  Xwayland gets the X11 behaviour (measured on nested KWin 5.27, issue #13). Native Wayland is the fallback: `window`
  and `kiosk` work, the corner widgets are reported once as unplaceable, drag-to-corner does not snap or save, and the
  widget size is corrected after the map. Still open: labwc under Xwayland places but does not keep above or below
  (spike, 0.7.1); GNOME and Plasma 6 are unmeasured; gtk-layer-shell would give native Wayland corners and stacking
  on KWin and labwc (3–5 days, spike in #13).
- Not a bug: under a headless KWin with no desktop shell the widget surround renders opaque; on the
  real Plasma session it is transparent.

## Packaging (2026-10-18)

- The first signed, notarised release: done. v2.0.0 and v2.1.0 ran the Release workflow on 2026-10-23 with the
  real Developer ID certificate; `spctl` reports "accepted, source=Notarized Developer ID", `stapler validate`
  passes, and the tap job updated the cask. Still true: pull the local tap clone before
  `brew audit --cask --online`, or it compares a stale version.
- Linux packages: done (issue #17). Each release attaches `.deb` packages for amd64 and arm64, built in a
  `debian:bookworm` container (no glibc symbol newer than 2.34), lintian-clean, and installed with plain apt and
  started under Xvfb in clean Debian 12 and Ubuntu 24.04 containers by `.github/workflows/linux_deb.yml`. Not yet
  run on a real Raspberry Pi. The sidecar image is built but not published to a registry. Windows is dropped for now (2026-10-18): nobody in the user base runs OVOS on it.

## Interactive notifications (2026-10-23, left out of the display-only popups)

The popups follow ovos-shell's NotificationPop*.qml.

- **Tap to dismiss.** Done (2026-10-23): the close button sends `ovos.notification.api.pop.clear.delete` with
  the popup's record.
- **Notification actions.** Done (2026-10-23): a tap on the text sends the record's `action` with its
  `callback_data`, then closes the popup.
- **The stored list.** Done (2026-10-23): the idle page's count badge opens the stored list, after the homescreen's
  idle.qml; an item's text runs its action and clears it (`storage.clear.item`), its ✕ and Clear all clear without
  running actions (`storage.clear.item`, `storage.clear`), unlike the Qt trash and Clear buttons. Each display lists
  its own WidgetManager's store: with several clients on one OVOS, the homescreen's `notification_model` is whichever
  client answered `request.storage.model` last (measured 2026-10-23: ovos-visage answers with an empty store).

## Input (2026-10-23)

- **Skill controls not ported yet.** OCP's Home skill chips (GridSkillCard.qml sends `featured_tracks.play`,
  which the installed OCP registers as `skill.play`, so the Qt page itself may not work), OCP's Search page
  (`search` and `play_search` with typed text), repeat and shuffle (the Qt buttons send nothing), and the alerts
  ListView's `neon.alerts.converse` (nothing in ovos-skill-alerts 0.6.6a2 handles it; its items carry no `ident`).
- **Seek lands between reports.** After a seek, the bar runs from the old position until OCP reports the new one.

- **On-screen keyboard.** The command box and SYSTEM_InputBox take a hardware keyboard, or the system's own
  on-screen keyboard where the desktop shows one for a focused text field (GNOME can; a bare Pi kiosk or labwc
  does not). A touch-only kiosk needs either a desktop that offers one or a keyboard drawn in the app.
- **Pinch to size the mouth in try-on mode** stays open (entry 5); the gesture table in SCOPE.md has room for it.
- **The two-finger tap** is tested with synthetic touches only; no touch screen was available on the development
  Mac. Check it on a Pi touch display and a touch laptop.

## Volume (2026-10-23)

- **Volume display and controls.** Done (2026-10-23): a brief row of dots in the status row for every change, and
  Volume up, Volume down and Mute in the menu and on the media keys, all over the generic `mycroft.volume.*` bus
  messages (SCOPE, Input). Verified live on macOS with ovos-phal-plugin-mac 0.2.4; the ALSA path is from source only.
- **No slider, no exact level.** A touch slider needs `mycroft.volume.set`, and its `percent` is a fraction for
  ovos-PHAL-plugin-alsa, ovos-skill-volume and ovos-shell but a whole percent for ovos-phal-plugin-mac (measured: a
  voice "set volume to 50 percent" set the Mac to 0). Revisit when the plugins agree.
- **ovos-phal-plugin-mac, upstream.** It reads `percent` as 0–100, and answers `mycroft.volume.get` with nothing at
  level 0, so the display cannot show a Mac at 0 (reported in the log). Both are plugin fixes, not client ones.
- **Media keys** are tested with synthetic key events only; check which desktops pass them to the app.

## Pre-announcement polish audit (2026-10-25)

Before the finished product is announced, every v2 feature is checked against `docs/DESIGN.md`. This list is the first
run of the guards in that guide's "Enforced by" table. Decide each item: fix it, or record why it is allowed.

Style (`test/style_rules_test.dart`, allowlist entries marked `audit:`):

- `lib/widgets/command_box.dart`: the typed-command box has an accent outline.
- `lib/widgets/volume_indicator.dart`: the volume pill is a filled rounded box; allow it as a status pill or redraw it.
- `lib/widgets/notification_stack.dart`: notification popups are filled rounded boxes, close to cards.
- `lib/window/window_menu.dart`: the in-window menu has an accent outline.
- `lib/window/window_menu.dart`: the in-window menu separators are accent, not the faint hairline.

Accessibility (`test/a11y_guidelines_test.dart`, skipped with `audit:` at 480 × 800 and 240 × 400):

- `lib/pages/sun_times_page.dart`: SUNRISE 4.02:1 and SUNSET 4.38:1 at 16 px, under 4.5:1.
- `lib/widgets/home_chips.dart`: the count badge, white on the accent, is 2.92:1 at 15 px; it is on both resting screens.
- `lib/pages/input_box_page.dart`: the Confirm label is 2.92:1 at 20 px, under 3:1.
- `lib/pages/text_frame_page.dart`: the recorded text "Hello" is 2.92:1 at 72 px, under 3:1.
- `lib/widgets/home_chips.dart`: the count badge is 28 px high, under the 48 px Android tap-target size (informative only).
- No fixture reaches three routes, so they are not checked: alerts `ListView`, OCP `OVOSSyncPlayer`, `SYSTEM_face`.

Reduced motion (`test/reduced_motion_test.dart`, files that animate and ignore the setting):

- `lib/face/face.dart`: the face ticker runs blink, widen and the mouth tween.
- `lib/lottie/cache_lottie.dart`: OVOS Lottie files play.
- `lib/pages/loading_page.dart`: the fallback thinking dots breathe.
- `lib/pages/now_playing_page.dart`: the cover turns like a record.
- `lib/pages/now_playing_status.dart`: the equaliser bars and the live dot pulse.
- `lib/pages/ocp_busy_page.dart`: the fallback dashed arc turns.
- `lib/pages/sun_times_page.dart`: the sun rises and settles over 8 s.
- `lib/pages/timer_page.dart`: an expired timer's ring pulses.

Impeller opacity over a blur: no opacity widget wraps a child that draws only a blur. Check two near cases on a device:

- `lib/pages/now_playing_page.dart`: the blurred cover wash fades an image inside its blur.
- `lib/pages/status_page.dart`: the failure state fades the whole chip, its glow included.

Other:

- `lib/pages/status_page.dart`: the comment says the glyph "blooms as it arrives", but no code blooms; add the bloom or
  correct the comment. No shared widget makes a one-time bloom (`docs/DESIGN.md`, Shared widgets).
- `lib/theme.dart`: the page background is `#05070A`; ovos-visage SPEC 9 gives `#0b0f14`.

## Carried over

- The web iframe cannot detect a site that refuses framing; a `/frameable` check in the sidecar
  would need more than nginx.
- A Dart recorder for protocol fixtures, so contributors do not need ovos-visage's `--record`.
- The `/res-abs/` route in the sidecar serves whatever is mounted under `/srv/host`; ovos-visage
  only served paths that had appeared in session data. Mount narrowly until the sidecar checks.
