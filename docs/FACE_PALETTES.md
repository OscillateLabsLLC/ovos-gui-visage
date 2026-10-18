# Face palettes: swappable eyes and mouths

The design for backlog item 5 (face customisation), now built: `lib/face/styles/` holds the
painters, `lib/face/styles.dart` the names and presets, `lib/face/face_spec.dart` the config form.
The sections below are the design as agreed; where the code settled a detail differently it is
noted in place. Today a `FaceTheme` bundles its eyes painter,
its mouth painter and its geometry, so a new face is a whole theme. This splits the face into two
palettes, nine eye styles and eight mouth styles, any eye with any mouth, so seventy-two faces
come out of seventeen painters. Colour is a later layer: every style reads the same colour tokens, so a palette
of colours multiplies the set again without new painters.

`docs/face-palettes.html` is an animated preview of every combination in all four attention
states and in the compact badge; open it in a browser (no build, no server).

## The contract

The face widget keeps owning the animation state and hands every painter the same `FaceFrame`:
mode, `eyeOpen`, `eyeScale`, the tweened `lips`, the `viseme` code, `elapsed`, `compact`. Two
things change.

1. **Styles draw into slots, not onto the frame.** A `FaceLayout` gives each painter its box:
   two eye slots (centre, radius) and a mouth slot (centre, width, height). The layout comes from
   the frame, not the style, so an eye style never knows whether it sits on the bare screen, in
   the badge disc, or in a Mark 1 ring well. Full layout: eyes at ±130 from centre, y 190, radius
   71; mouth centred at y 480, 318 × 159 (the visage numbers, kept so `visage` renders unchanged).
   Compact layout: the stacked badge the Mark 1 theme already uses, eyes radius 30 above a
   190 × 60 mouth.
2. **A face is a composition.** `FaceTheme` stays the type the widget consumes; `ComposedTheme
   (eyes, mouth, frame)` implements it, and the two shipped themes become presets:
   `visage = lens + outline`, `mark1 = ring + matrix + plate`. The frame is the optional backdrop
   (none, or the Mark 1 plate, which also supplies its own layout: the ring wells and the matrix
   window).

Each style owns its own listen, think, speak and blink behaviour. The widget does not animate
styles; it only reports state, and every style must read legibly in all four modes and in the
badge. That is the test for admitting a style, and it is what the preview page shows.

## Eye styles

| name | at rest | listening | thinking | blink |
|---|---|---|---|---|
| **lens** (visage today) | grey ring with a white highlight arc on top | widen flash, then normal | squashed to a narrow ellipse | vertical squash |
| **ring** (Mark 1 today) | 12 LEDs on a dark well | all lit | the firmware squint: top and bottom pairs off | pixel pairs off from the top and bottom inward |
| **block** | solid rounded square, the Cozmo and Vector family | taller and brighter | shorter, the inner top corner cut away so the eyes slant in | squash to a slit |
| **visor** | one bar spanning both eye slots, bright at the centre | a scanner highlight sweeps end to end | the bar contracts to its middle and pulses | thins to a line |
| **aperture** | a camera lens: glass, iris blades, dark pupil with a highlight | the iris opens wide | the iris contracts and the pupil darts | the blades close |
| **mono** | one aperture lens at the midpoint, accent in the glass | as aperture | as aperture | as aperture |
| **oval** | elongated glowing ovals, slightly tilted | lifted and taller | narrowed and tilted inward | flattened |
| **pixel** | 8 × 8 LED matrix eyes with a dark pupil | brighter glow | the pupil shifts up and sideways under a squint | rows off from the top and bottom inward |
| **dot** | two small filled dots | the dots grow | the dots drift up and together | the dots become dashes |

The eye slots are symmetric, so `block` mirrors its slant and `visor` reads both slots as its
endpoints. `ring` without the plate frame draws its well on black with the LED glow, which is the
look of a Mark 1 face without the faceplate.

## Mouth styles

| name | speaking | at rest | listening | thinking |
|---|---|---|---|---|
| **outline** (visage today) | hollow round-capped viseme outline, tweened | the closed smile | seven breathing accent bars | the smile, still |
| **solid** | the same viseme outline, filled | a short filled smile | a dot that breathes | a short line tilted a few degrees |
| **matrix** (Mark 1 today) | the firmware viseme bitmaps on 32 × 8 LEDs | dark grid | the firmware waveform loop | the dot bouncing end to end |
| **waveform** | one stroke on a shallow smile whose amplitude and span follow the viseme; the smile flattens as the viseme opens | the smile line, still | a low accent ripple travelling along the line | three dots pulsing in turn |
| **bars** | a vertical equaliser: the viseme opening sets the heights and its width how many bars rise | stubs along a shallow smile | the breathing accent bars | one bar scanning across |
| **grille** | horizontal speaker slats lit outward from the centre by the viseme opening | dim slats | the slats breathe in the accent | one slat scanning up and down |
| **orb** | a ring that swells with the viseme and throws concentric rings | a dim ring | a breathing accent ring | a rotating arc |
| **none** | no mouth; the eyes pulse in brightness with the viseme | nothing | the eyes alone | the eyes alone |

`outline` and `solid` draw `frame.lips`, so they cost nothing new in the widget; `matrix` draws
by `frame.viseme`; `waveform` maps the viseme's opening to an amplitude, its width to a span and
its corner lift to the smile, using the shape table in `visemes.dart` rather than a table of its own.
The smile baseline is there so that the mouth never rests as a bare horizontal bar: paired with
`visor`, a flat line read as a second visor rather than a face.

## Mouth size

A larger mouth is a layout parameter, not a fifth style: `mouthSize: large` scales the mouth slot
by 1.4 (1.25 in the badge, where the disc bounds it), so every mouth has a big version and the
stroke weight grows with the slot. Large `outline` is the visage mouth at 250 px wide instead of
178, which is the version that reads from across a room.

## Presets worth naming

The combinations that read as their own character, to ship as named presets beside `visage` and
`mark1`:

- `visor + matrix`: a single scanner eye over an LED mouth; the 1980s computer.
- `block + solid`: the toy robot; the most expressive pair, eyes and mouth both squash.
- `ring + waveform`: Mark 1 eyes with a smooth voice line, for people who want the LEDs without
  the matrix.
- `lens + matrix`: the concept face with a retro mouth.
- `aperture + grille`: binocular lenses over speaker slats; the camera robot.
- `oval + none`: glowing ovals and no mouth; the pod robot.
- `pixel + matrix`: an all-LED face.
- `mono + orb`: one lens, one ring; the ship's computer.
- `dot + bars`: dots over an equaliser; the desk buddy.

Everything else is still valid, just less distinct; the preview grid shows all sixteen.

## Configuration

`"face"` stays a string for presets and takes an object for a composition:

```json
{"face": "mark1"}
{"face": {"eyes": "block", "mouth": "outline", "mouthSize": "large"}}
{"face": {"eyes": "ring", "mouth": "matrix", "frame": "mark1-plate"}}
```

`VISAGE_FACE` keeps overriding with a preset name or `eyes+mouth` (`VISAGE_FACE=block+outline`).
Switching at runtime, the other half of backlog item 5, is a `FaceController.theme` setter the
widget already almost has; a key in window mode and a client-only bus message would both drive it,
and neither needs OVOS changes.

## Colour, later

Every style reads five tokens and nothing else: `eye`, `eyeDim`, `mouth`, `accent`, `glow`. The
visage and Mark 1 values are the first two colourways. Parameterising those tokens is a config
field on the same `"face"` object and no new painting.

## Changing the face in the interface

The first pass is the picker page and direct manipulation, with the bus as the one path.

- `docs/face-palettes.html` connects to the bus when served by the sidecar (`/faces.html`) or
  opened with `?bus=`, sends `visage.face.set` on every tap and follows `visage.face.state`, so
  it is a remote for the device and stays in step with any other way of changing the face.
- Try-on mode (`lib/face/try_on.dart`): long-press to enter, swipe across the eyes or the mouth
  to cycle, swipe the mouth up or down for size, tap when done. The mouth speaks a demo loop
  while trying on. Settled differently from the proposal: a vertical swipe sizes the mouth, not
  a pinch, because a pan recogniser and a scale recogniser fight over the same drag.
- `FaceRemote` (`lib/face/face_remote.dart`) is the bus side; every change, from either surface
  or from the bus, is written back to the config file as the `face` object.
- Voice is the next layer: a companion skill mapping phrases to `visage.face.set`.

## Order of work

1. `FaceLayout` and `ComposedTheme`; wrap the four existing painters as styles. Visage and Mark 1
   must render pixel-identical (compare against `docs/screenshots/face/`).
2. `waveform` and `block`, the two that add the most range.
3. `visor` and `solid`.
3a. `aperture` (with `mono` as its single-lens parameter), `oval`, `bars`, `orb` and `none`; then
   `pixel`, `dot` and `grille`, which share most of their drawing with `matrix`, `solid` and `bars`.
4. Config parsing, presets, `VISAGE_FACE` with `+`.
5. Runtime switching.

Each step is its own commit with the face tests extended: every style gets the same frame cases
(rest, listen, think, each viseme, closed eyes, compact) and must paint without faults.
