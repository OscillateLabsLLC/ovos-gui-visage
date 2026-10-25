# ovos-gui-visage

Flutter GUI client for OpenVoiceOS in the 2018 Mark II Kickstarter concept style; the native
port of ovos-visage. **Read `docs/SCOPE.md` first**, then ovos-visage's `docs/SPEC.md` for the
protocol and visual reference (`../ovos-visage/docs/SPEC.md` in Mike's checkout).

## Hard rules

- **Never modify the live install.** The OVOS on this Mac (`~/.venvs/ovos`, `~/.venvs/ovos-gui`, bus 8181,
  GUI 18181) is read-only and never a test target. Upstream OVOS work is in scope, in separate clones and virtualenvs
  (today `~/coding/OscillateLabs/gui1-upstream/`, `~/.venvs/ovos-gui1*`), as PRs from OscillateLabsLLC forks.
- **Never install into or upgrade the live install's virtualenvs.** `ovos-gui-service` and the
  homescreen live in `~/.venvs/ovos-gui`; this app has no Python of its own.
- **Branch + PR, never push `main`.** A maintainer merges. Conventional commit titles.
- **Deterministic evidence.** Run the change against the live stack and look. ovos-visage's
  drivers (`docs/spike_say.py`, `tests/manual/demo.py`, `tests/manual/show_templates.py`) only
  talk to the bus, so they drive this app unchanged. Paste the evidence in the PR.
- One logical action per Bash call; no `;`-chained unrelated commands.
- **Never swallow a failure.** No empty catch, no silent `return null`. Where the display
  survives by showing a fallback, call `reportFault` (`lib/faults.dart`) first; protocol
  faults are logged with payload and stack. A test that exercises a fallback asserts the
  report (`test/faults.dart`).

## Running the stack (two processes plus OVOS)

```bash
~/.venvs/ovos-gui/bin/ovos-gui-service
~/.venvs/ovos-gui/bin/ovos-skill-launcher ovos-skill-homescreen.openvoiceos
VISAGE_MODE=window flutter run -d macos   # the default mode is a desktop widget in a corner
```

## Conventions

- Targets: macOS first; Linux and web build in CI; the web build runs behind `sidecar/`. No Windows.
  No iOS, no Android. `dart:io` lives only in `lib/resources/platform_io.dart` and
  `lib/protocol/endpoints_io.dart` (conditional exports), or the web build stops compiling.
- macOS app sandbox is off (local sockets, reads `~/.cache/ovos_gui`); signed with the
  Oscillate Labs LLC team.
- `flutter analyze --fatal-infos` and `dart format --line-length 130` are clean; `flutter test`
  is green. Functions under 30 lines, files under 300, no narrating comments.
- Design rules (vocabulary, shared widgets, motion, glanceability, goldens) are in `docs/DESIGN.md`; read it before
  adding a page, widget or animation.
- Pages are `StatelessWidget`s or small `StatefulWidget`s with a static `page(Json, PageContext)`
  builder registered in `lib/pages/router.dart`. Pure view models live beside them and are
  unit tested; widget tests pump the pages from the recorded fixtures.
- The face is a `ComposedTheme`: a backdrop hands slots to an `EyeStyle` and a `MouthStyle`
  (`lib/face/styles/`), named in `lib/face/styles.dart` and chosen by a `FaceSpec`. `visage` and
  `mark1` are presets and have goldens (`test/goldens`, macOS only); every pairing must paint
  every frame without a fault (`test/styles_test.dart`). Mark 1 bitmaps are generated into
  `mark1_images.g.dart` by `tool/port_mark1_images.py`; never edit them by hand. New styles get
  a sketch in `docs/face-palettes.html` first; that page is also the device's picker over the bus.
  Its text is for non-technical users: a new style or preset also needs a plain name in its `NAMES`
  or `presets`, and no code names, hex values or jargon on the page.
- Colour is a `FacePalette` (`lib/face/face_palette.dart`) on every `FaceFrame`; styles read
  `frame.palette` for anything a colourway should change; fixed hardware greys stay in `HardwareColours`. The page's
  `palettes` object must stay in sync with the named colourways.
- The face changes at runtime through `FaceRemote` (`visage.face.*` on the bus) and try-on mode
  (`lib/face/try_on.dart`, long-press); both persist through `saveFaceConfig`.
- Window modes: `desktop` and `float` are corner widgets, `window` is ordinary, `kiosk` fills the
  screen (`lib/window/kiosk_*.dart`, `window_surface.dart`, `macos/Runner/Kiosk.swift`). Kiosk is not
  a widget (`isWidget` is false), never peeks, and can be entered from and left to any mode;
  `WindowRemote.setMode` owns the rules and `saveWindowConfig` keeps the mode.
- Peek mode (`lib/window/peek.dart`): a widget idles as a `FaceBadge` and the window grows while
  `Attention.shown`; `WindowRemote` drives it with `visage.window.*`, `saveWindowConfig` keeps it.
- The macOS menu bar item: `lib/window/status_menu.dart` builds the items from the window and face
  state (pure, tested) and acts through `WindowRemote` and `FaceRemote`; `status_menu_host*.dart`
  and `macos/Runner/StatusMenu.swift` draw it over the `ovos_gui_visage/window` channel. Add a
  menu choice in Dart; the runner draws whatever list it gets. Face picker… and `visage.face.picker`
  both call `FaceRemote.openPicker`; `lib/window/face_picker*.dart` writes the bundled
  `docs/face-palettes.html` to `faces.html` beside the config plus `open-faces.html`, which redirects to
  `faces.html#bus=…` (macOS drops a file URL's fragment), and the runner's `openUrl` opens the launcher.
- Input (`docs/SCOPE.md`, Input): pages hold plain controls (buttons, text fields, sliders) that answer through
  `PageContext.trigger` (`lib/protocol/gui_events.dart`) and never read raw pointers or keys. The shell owns the
  gestures: `WindowSurface` (drag-to-move, right-click / two-finger tap / Menu key for the in-window menu, arrow keys),
  `PagePager` (a clearly horizontal swipe on a multi-page skill, kiosk chevrons, `system.gui.user.interaction`),
  try-on's long-press and the peek badge's tap. A new gesture gets a row in SCOPE's table first. Every outgoing
  message has a fixture in `test/fixtures/outgoing/`, recorded from the live bus or labelled as written from source.
- Volume: `lib/volume.dart` (pure model: level, mute, show and fade) and `lib/volume_controls.dart` speak only the generic
  `mycroft.volume.*` messages the PHAL volume plugins handle; Visage never touches an audio device. Do not send
  `mycroft.volume.set`: its `percent` is a fraction for the ALSA plugin and a whole percent for the Mac plugin.
