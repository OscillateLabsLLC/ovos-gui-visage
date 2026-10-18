# ovos-gui-visage

Flutter GUI client for OpenVoiceOS in the 2018 Mark II Kickstarter concept style; the native
port of ovos-visage. **Read `docs/SCOPE.md` first**, then ovos-visage's `docs/SPEC.md` for the
protocol and visual reference (`../ovos-visage/docs/SPEC.md` in Mike's checkout).

## Hard rules

- **Never modify OVOS code** (`ovos-gui`, skills, workshop). If the protocol does not do what
  you need, change the client, or stop and report.
- **Never install into or upgrade the virtualenv OVOS runs from.** `ovos-gui-service` and the
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
flutter run -d macos
```

## Conventions

- Targets: macOS first; Linux, Windows and web build in CI; the web build runs behind `sidecar/`.
  No iOS, no Android. `dart:io` lives only in `lib/resources/platform_io.dart` and
  `lib/protocol/endpoints_io.dart` (conditional exports), or the web build stops compiling.
- macOS app sandbox is off (local sockets, reads `~/.cache/ovos_gui`); signed with the
  Oscillate Labs LLC team.
- `flutter analyze --fatal-infos` and `dart format --line-length 130` are clean; `flutter test`
  is green. Functions under 30 lines, files under 300, no narrating comments.
- Pages are `StatelessWidget`s or small `StatefulWidget`s with a static `page(Json, PageContext)`
  builder registered in `lib/pages/router.dart`. Pure view models live beside them and are
  unit tested; widget tests pump the pages from the recorded fixtures.
- The face is themed through `FaceTheme` (eyes painter, mouth painter, geometry). First pass
  ships only `VisageTheme`.
- Display-only. Touch is a later, additive scope: no gesture plumbing in pages yet.
