# Faces: eyes, mouths, backdrops and colourways

A face is a composition: a backdrop places two eye slots and a mouth slot, an eye style draws in
the eye slots, a mouth style draws in the mouth slot, and a palette supplies the colours. Nine eye
styles, eight mouth styles, two backdrops, two mouth sizes and six colourways ship; any eye goes
with any mouth. The painters live in `lib/face/styles/`, the names in `lib/face/styles.dart`, the
colourways in `lib/face/face_palette.dart`, and `lib/face/face_spec.dart` turns a config value
into a theme.

`docs/face-palettes.html` is the picker. It leads with the presets as cards; "Customise this face"
(closed by default, `#customise` opens it) holds the eye, mouth, size and colour choices with a
preview of each attention state and the compact badge, and "Show every combination" (`#all`)
draws all seventy-two pairings. It names every style in plain words, so a new style needs a name
there too. Opened from the menu bar (Face picker…), served by the sidecar at `/faces.html`, or
opened with `#bus=ws://host:8181/core`, it sends `visage.face.set` on every choice, shows "Saved"
once `visage.face.state` answers, and follows `visage.face.state`, so it stays in step with the
device however the face was changed. `tool/test_picker.py` tests the page in headless Chrome
against a fake bus: the arrow keys, Space and Enter, taps, "Saved" and "Not saved", Undo, the
two links and reduced motion.

## How the pieces fit

The face widget owns the animation state (mode, blink, widen, the tweened lips, the viseme code,
elapsed time, the compact flag, the palette) and hands every painter the same `FaceFrame`. Styles
only draw.

- A `FaceBackdrop` gives a `FaceLayout`: two `EyeSlot`s (centre, radius) and a `MouthSlot`
  (centre, width, height), for the full face and for the compact badge. `none` is the bare screen:
  eyes 130 either side of centre at y 190, radius 71, the mouth box centred at y 480; the badge uses
  the same layout inside a disc of radius 363. `mark1` is the Mark 1 faceplate: it paints the glass
  and takes its slots from the ring wells and the matrix window, stacked in the badge.
- An `EyeStyle` paints into the eye slots and a `MouthStyle` into the mouth slot. A style never
  knows which backdrop it sits on.
- `ComposedTheme(backdrop, eyeStyle, mouthStyle, mouthScale, palette)` is the `FaceTheme` the
  widget consumes. `visage` is `lens + outline` and `mark1` is `ring + matrix` on the plate with
  the `mark1` colourway; both are held to goldens in `test/goldens`.
- Every style must read in all four attention states, with closed eyes and in the badge;
  `test/styles_test.dart` paints every pairing through every frame and fails on any fault.

## Eye styles

| name | at rest | listening | thinking | blink |
|---|---|---|---|---|
| **lens** (visage) | grey ring with a white highlight arc on top | widen flash, then normal | squashed to a narrow ellipse | vertical squash |
| **ring** (Mark 1) | 12 LEDs on a dark well | all lit | the firmware squint: top and bottom pairs off | pixel pairs off from the top and bottom inward |
| **block** | solid rounded square, the Cozmo and Vector family | taller and brighter | shorter, the inner top corner cut away so the eyes slant in | squash to a slit |
| **visor** | one bar spanning both eye slots, bright at the centre | a scanner highlight sweeps end to end | the bar contracts to its middle and pulses | thins to a line |
| **aperture** | a camera lens: glass, iris blades, dark pupil with a highlight | the iris opens wide | the iris contracts and the pupil darts | the blades close |
| **mono** | one aperture lens at the midpoint, accent in the glass | as aperture | as aperture | as aperture |
| **oval** | elongated glowing ovals, slightly tilted | lifted and taller | narrowed and tilted inward | flattened |
| **pixel** | 8 × 8 LED matrix eyes with a dark pupil | brighter glow | the pupil shifts up and sideways under a squint | rows off from the top and bottom inward |
| **dot** | two small filled dots | the dots grow | the dots drift up and together | the dots become dashes |

The eye slots are symmetric, so `block` mirrors its slant and `visor` reads both slots as its
endpoints. `ring` on the bare screen draws its well on black with the LED glow, the look of a
Mark 1 face without the faceplate.

## Mouth styles

| name | speaking | at rest | listening | thinking |
|---|---|---|---|---|
| **outline** (visage) | hollow round-capped viseme outline, tweened | the closed smile | seven breathing accent bars | the smile, still |
| **solid** | the same viseme outline, filled | a short filled smile | a dot that breathes | a short line tilted a few degrees |
| **matrix** (Mark 1) | the firmware viseme bitmaps on 32 × 8 LEDs | dark grid | the firmware waveform loop | the dot bouncing end to end |
| **waveform** | one stroke on a shallow smile whose amplitude and span follow the viseme; the smile flattens as the viseme opens | the smile line, still | a low accent ripple travelling along the line | three dots pulsing in turn |
| **bars** | a vertical equaliser: the viseme opening sets the heights and its width how many bars rise | stubs along a shallow smile | the breathing accent bars | one bar scanning across |
| **grille** | horizontal speaker slats lit outward from the centre by the viseme opening | dim slats | the slats breathe in the accent | one slat scanning up and down |
| **orb** | a ring that swells with the viseme and throws concentric rings | a dim ring | a breathing accent ring | a rotating arc |
| **none** | no mouth; the eyes pulse in brightness with the viseme | nothing | the eyes alone | the eyes alone |

`outline` and `solid` draw the tweened `frame.lips`; `matrix` draws by `frame.viseme`;
`waveform` and `bars` map the viseme's opening, width and corner lift onto their own shapes using
the table in `visemes.dart`. The waveform rests on a shallow smile rather than a flat line because
a flat line under `visor` read as a second visor.

## Mouth size

`mouthSize` is a layout parameter, not a style: `large` scales the mouth slot by 1.4, so every
mouth has a big version and stroke weights grow with it. Each backdrop caps the scale: the bare
screen allows it everywhere, the Mark 1 plate allows none, since the matrix window is the size it
is. Large `outline` is the visage mouth at 250 px wide instead of 178, the version that reads from
across a room.

## Presets

| name | eyes + mouth | the idea |
|---|---|---|
| `visage` | lens + outline | the 2018 concept face |
| `mark1` | ring + matrix on the plate, `mark1` colours | the Mark 1 |
| `scanner` | visor + matrix | one eye over an LED mouth |
| `robot` | block + solid | the toy robot; eyes and mouth both squash |
| `retro` | ring + waveform | LED eyes with a smooth voice line |
| `hybrid` | lens + matrix | the concept face with a retro mouth |
| `camera` | aperture + grille | binocular lenses over speaker slats |
| `pod` | oval + none | glowing ovals and no mouth |
| `led` | pixel + matrix | an all-LED face |
| `orbit` | mono + orb | one lens, one ring |
| `buddy` | dot + bars | dots over an equaliser |

A preset sets eyes, mouth, backdrop and colourway. Choosing one keeps only the mouth size. Every
other pairing is valid, just less distinct; the picker grid shows all seventy-two.

## Colour

A `FacePalette` rides on every `FaceFrame`, and styles read `frame.palette` for anything a
colourway should change. The tokens are `eye`, `eyeDim`, `mouth`, `accent` (listening, and the
colour that stands apart from the eyes), `led` (a lit Mark 1 ring LED), `matrix` (a lit matrix LED)
and `matrixGlow` (the halo around a lit matrix mouth LED, which on the Mark 1 is a different blue
from the LED itself). The dark hardware greys (unlit LEDs, the lens housing and blades, the matrix
panel) are fixed in `HardwareColours`, as are the Mark 1 faceplate and the aperture glass.

| name | eye | accent | idea |
|---|---|---|---|
| `visage` | `#F5F5F5` | `#1E9BFF` | the original colours; the goldens hold them |
| `ember` | `#FFB547` | `#FF5E1A` | amber eyes, a hotter red-orange accent |
| `mint` | `#8FF0C8` | `#B28DFF` | mint, a lavender accent on the far side of the wheel |
| `rose` | `#FFA8C0` | `#3FD3C6` | pink, its teal complement |
| `ice` | `#CDEEFF` | `#8C7BFF` | pale blue-white, a violet accent so it does not read as more blue |
| `mark1` | `#70656A` | `#ADDEFB` | the Mark 1 ring colour on eyes, its matrix colours on mouths |

Each colourway sets `led` and `matrix` from its own family, so the ring, pixel and matrix styles
take the colour too. A test holds every accent clearly apart from its eye colour. The picker page
keeps a copy of these values for its canvases; `lib/face/face_palette.dart` is the source and the
two must match.

## Configuration

`face` in `~/.config/ovos-gui-visage/config.json`, or `VISAGE_FACE` on top of it:

```json
{"face": "mark1"}
{"face": "retro+large+rose"}
{"face": {"eyes": "block", "mouth": "outline", "mouthSize": "large", "colours": "ember"}}
{"face": {"preset": "pod", "colours": {"eye": "#FFD166", "accent": "#EF476F"}}}
```

The string form is `+`-separated names in any order, each a preset, eye, mouth, size, backdrop or
colourway; later names win. The object form takes `eyes`, `mouth`, `mouthSize`, `backdrop` and
`colours` (a name, or an object of `#RRGGBB` or `#AARRGGBB` tokens; missing tokens are visage's);
a `preset` key resets the rest first. An unknown name is reported as a fault and the visage part is
used in its place. Whatever changes the face while running writes it back to this file.

## Changing the face while running

- **The menu bar.** Face and Colours submenus list the presets and colourways; Face picker… opens
  the page below in the browser, connected to the local bus.
- **The picker page**, as a remote. Every tap sends `visage.face.set`; the page follows
  `visage.face.state`, so two pickers, the menu and try-on all agree.
- **The bus.** `visage.face.set` with any of `preset`, `eyes`, `mouth`, `mouthSize`, `backdrop`,
  `colours`; `visage.face.get`; `visage.face.state` as the answer to both and after every change,
  with the names available for each part under `available`; `visage.face.picker` opens the page.
  Client-only messages: nothing in OVOS sends them. `lib/face/face_remote.dart`.
- **Try-on mode** on the face itself (`lib/face/try_on.dart`): long-press to enter, swipe across
  the eyes or the mouth to cycle, swipe the mouth up or down for size, tap when done. The mouth
  speaks a demo loop while trying on. A vertical swipe sizes the mouth rather than a pinch, because
  a pan recogniser and a scale recogniser fight over the same drag. There is no colour gesture.
- **Voice** is the next layer: a companion skill mapping phrases to `visage.face.set`.
