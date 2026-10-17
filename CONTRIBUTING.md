# Contributing to ovos-gui-visage

Contributions are welcome: pages, protocol fixes, visual work, face themes, and tests.

## Development Setup

- Flutter 3.47 or newer (`flutter doctor` clean for the desktop you build on)
- [just](https://github.com/casey/just) (optional; every recipe has a `flutter` equivalent)

```bash
git clone https://github.com/OscillateLabsLLC/ovos-gui-visage
cd ovos-gui-visage
just sync          # flutter pub get
just test          # flutter test
just lint          # dart format check + flutter analyze
just run           # flutter run -d macos
```

## Protocol rule

ovos-visage's `docs/SPEC.md` is the contract. Protocol behaviour is tested from recorded
traffic in `test/fixtures/*.jsonl`; `test/fixtures/expected/` holds the Python reference's
state snapshot per fixture, and `gui_state_test.dart` requires a match. When you change how a
GUI message is handled, record the real sequence from a live `ovos-gui-service` with
`ovos-visage --record`, add it as a fixture, and regenerate the goldens from the Python
reference. Never change OVOS code to make the client work.

## Visual rule

Circles, rings and plain stacked text on black. No cards, nested panels, accent borders or
edge stripes; gradients, glows and motion are welcome. Reuse `lib/widgets/circle.dart`
(`Circle`, `Ring`, `Glow`, `StaggerEnter`, `RiseIn`) rather than inventing per-page effects.
The fallback debug card is the one exception.

## Verifying a change

A green test run proves the state machine and view models. A visible change needs the stack
running and eyes on the screen: ovos-visage's `docs/spike_say.py`, `tests/manual/demo.py`
and `tests/manual/show_templates.py` drive this app unchanged. Paste what you saw in the PR.

## Pull Requests

1. Create a branch: `git checkout -b feat/my-change` or `fix/my-change`
2. Add tests for the change
3. Run `just lint` and `just test`
4. Open a pull request with a conventional commit title (`feat:`, `fix:`, `chore:`, `docs:`)

A maintainer merges. Releases are cut by release-please from the conventional commits.
