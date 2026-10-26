# Visage design guide

This guide collects the design rules in one place. The source is ovos-visage's SPEC, section 9 "Visual design",
which follows the Mark II Kickstarter stills and demo video. Each rule names the file that implements or enforces it.
Read it before you add a page, a widget or an animation.

## Vocabulary

- Use a black background. Show content as big circular chips, stacked vertically and centred.
- Use circles, rings and plain stacked text. Do not use cards, nested panels, accent borders or edge stripes.
- Use gradients, glows and motion as polish.
- On the resting screen, stack the weather above the clock. Show a small logo badge only when nothing else is available.
  On GUI-1 the display owns the resting screen, not a skill
  ([gui-1.md 6.9 Idle / resting display ownership](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#69-idle--resting-display-ownership)),
  and fills it from the kept ambient data
  ([gui-1.md 6.9.1 Ambient data](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md#691-ambient-data)).
- The weather chip shows the last `gui.ambient.weather` for three hours from its arrival, then the clock stands alone
  until the next one (`lib/pages/resting_model.dart`). A clear sky takes the night icon from 20:00 to 06:00 by the
  device clock, since the spec's condition codes have no night variant (docs/GUI1_FINDINGS.md F53).
- Every clock reads the device's 12-hour or 24-hour setting (`clockView` in `lib/widgets/device_clock.dart`); no
  template or ambient topic carries one.
- Use white text, one blue accent, and yellow for the sun. Use the system font. Do not use web fonts.
- The colours are tokens in `lib/theme.dart`. Its page background is `#05070A`; SPEC 9 says `#0b0f14`
  (docs/BACKLOG.md, Pre-announcement polish audit).
- Write the words a user sees for people who are not technical. Do not show code names, colour values or jargon.
  The face picker page follows this rule (`CLAUDE.md`, Conventions).

## Shared widgets and polish vocabulary

Use these widgets. Do not make a new effect for one page.

| Widget | Use it for | Timing |
|---|---|---|
| `Circle` (`lib/widgets/circle.dart`) | Every chip: a filled or gradient circle with its content centred | — |
| `Ring` (`lib/widgets/circle.dart`) | A track and a value arc from twelve o'clock, for progress | 900 ms to a new value |
| `Glow` (`lib/widgets/circle.dart`) | The soft halo behind a hero circle; `loop` makes it swell for a held state | 6 s each way; 1.1 s each way when looping |
| `gradientFill` (`lib/widgets/circle.dart`) | The lit-from-above fill of a hero circle | — |
| `StaggerEnter` (`lib/widgets/circle.dart`) | A column whose items fade and rise in | 260 ms each, 60 ms apart |
| `RiseIn` (`lib/widgets/circle.dart`) | One item of a list that is not a plain column, with the same entry | 260 ms, 60 ms per index |
| `MotionIcon` (`lib/widgets/motion_icon.dart`) | The animated weather and status icons, from their SVG keyframes | per icon |
| Home chips (`lib/widgets/home_chips.dart`) | The weather chip, the clock chip and the notification badge of both resting screens | — |

A bloom swells the glow when a state arrives. A held state keeps it swelling: a ringing alarm uses a looping red
`Glow` (`lib/pages/alarms_page.dart`). No widget makes a one-time bloom yet (docs/BACKLOG.md, Pre-announcement polish audit).

## Motion rules

- Keep each animation short: under 60 lines of code.
- Stop every animation when the platform asks for reduced motion, and draw a defined still frame.
  Read `MediaQuery.maybeDisableAnimationsOf`, or `motionReduced` in `lib/widgets/circle.dart`.
  The glow holds a mid-breath frame. Entering items stand in place at full opacity. A ring shows its value at once.
- Do not put an opacity widget over a widget that draws only a blur. Impeller drops it (measured 2026-10-18).
  Scale the shadow's alpha instead, as `Glow` does.

## Glanceability

A user reads the screen from across the room, often in one look.

- Give each chip one hero element: the time, the temperature, an icon.
- Use big numerals. Do not shrink text to make it fit; show less instead.
- Know the space a page gets. The frame is 480 × 800, and the shell pads it, so a page gets 432 × 736. While the face
  is the strip at the bottom, the page gets 432 × 650 (`lib/screen_frame.dart`).
- The 240 × 400 corner widget is the same frame scaled by half (a fitted box in `lib/main.dart`), not a layout of its
  own. Text there is half size, so check that the smallest text still reads.
- Check every page at 432 × 736 and at 432 × 650.
- Keep text contrast at the guideline: 4.5:1 for normal text, 3:1 for large text.
- A page holds plain controls (buttons, text fields, sliders). It never reads raw touches or keys. The shell owns the
  gestures (`docs/SCOPE.md`, Input). Give every control a label.

## Faults, not silence

When a page cannot show what it was sent, do two things:

1. Report it with `reportFault` (`lib/faults.dart`). It goes to the log, and a test fails unless it expects it.
2. Show a degraded presentation the user can see: the fallback card, a text summary, or the chip without its icon.

Never show an empty screen without a report. Never hide a failure in an empty `catch`.

## Goldens

- A face preset needs goldens: `visage` and `mark1` have them in `test/goldens` (`test/face_golden_test.dart`).
- A page whose look is new needs a golden when a widget test cannot prove the look.
- Goldens run on macOS only, because canvas output differs between platforms. Continuous integration runs Linux.

## Enforced by

| Test | It fails when |
|---|---|
| `test/style_rules_test.dart` | a card, a filled box with rounded corners, a border with a width, or a divider other than the hairline is outside its allowlist |
| `test/a11y_guidelines_test.dart` | a page fails text contrast or labelled tap targets, at 432 × 736 or 432 × 650, and is not on the audit list; or the rendering library reports a fault while it lays out at either size (an overflowing flex) |
| `test/resting_centering_test.dart` | the resting chips leave the page's centre line, on either resting screen |
| `test/reduced_motion_test.dart` | a file that animates does not read the reduced-motion setting and is not on the audit list |
| `test/circle_motion_test.dart` | the shared widgets move under reduced motion |
| `test/styles_test.dart` | a face pairing does not paint every frame without a fault |
| `test/motion_test.dart` | an animated icon layer has no motion or painter |

Each allowlist and audit entry has a reason. An entry marked `audit:` is not known to be allowed;
docs/BACKLOG.md lists it under "Pre-announcement polish audit".
