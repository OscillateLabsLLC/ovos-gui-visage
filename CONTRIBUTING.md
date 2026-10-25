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
just conformance   # docs/GUI1_CONFORMANCE.md matches the template names
just test test/style_rules_test.dart test/a11y_guidelines_test.dart test/reduced_motion_test.dart  # docs/DESIGN.md guards
just lint          # dart format check + flutter analyze
just run           # flutter run -d macos
```

## Protocol rules

Visage speaks two protocols, and each has its own contract:

- **Legacy** (ovos-gui 1.x, the GUI socket on port 18181): ovos-visage's `docs/SPEC.md` is the
  contract. Protocol behaviour is tested from recorded traffic in `test/fixtures/*.jsonl`;
  `test/fixtures/expected/` holds the Python reference's state snapshot per fixture, and
  `gui_state_test.dart` requires a match. When you change how a GUI message is handled, record
  the real sequence from a live `ovos-gui-service` with `ovos-visage --record`, add it as a
  fixture, and regenerate the goldens from the Python reference.
- **GUI-1** (an OVOS-GUI-1 adapter, port 18182): the contract is
  [gui-1.md](https://github.com/OpenVoiceOS/architecture/blob/b6c1583/gui-1.md) in
  `OpenVoiceOS/architecture`, pinned at `b6c1583`, together with the adapter wire protocol in
  gui1-upstream `WIRE.md`. Fixtures are in `test/fixtures/gui1/`: hand-written ones say what they
  were written from in their first line, and `recorded/` holds the adapter's and the demo skill's
  recordings. `docs/GUI1_CONFORMANCE.md` tracks every clause, and `docs/GUI1_FINDINGS.md` every
  place where the code and the spec disagree.

The OVOS install you use every day is read-only to this work: never install into it, upgrade it
or point an experimental service at it. Visage may connect to it as a client, to record or to
check a change. A change to OVOS code is in scope: make it in a separate clone and virtualenv on
its own ports, and send it upstream as a PR. When the code and GUI-1 disagree, follow the
Process in `docs/GUI1_FINDINGS.md`: propose the spec change, and make the code follow the
proposed text.

## Visual rule

Circles, rings and plain stacked text on black. No cards, nested panels, accent borders or
edge stripes; gradients, glows and motion are welcome. Reuse `lib/widgets/circle.dart`
(`Circle`, `Ring`, `Glow`, `StaggerEnter`, `RiseIn`) rather than inventing per-page effects.
The exceptions are the allowlist in `test/style_rules_test.dart`, each with its reason; an entry
marked `audit:` still waits for a decision (`docs/BACKLOG.md`). The full guide, with motion and
glanceability rules, is `docs/DESIGN.md`.

## Icons

The animated icons live as plain SVGs with CSS keyframes in `assets/icon_sources/`. Flutter
runs no CSS, so `python3 tool/split_icons.py` (stdlib only) splits each one into layer
assets under `assets/icons/` and regenerates `lib/widgets/icon_layers.g.dart`; the keyframes
are transcribed by hand into `lib/widgets/icon_motion.dart`, keyed by icon, class and
ordinal. `test/motion_test.dart` fails if an animated layer has no motion or painter.

## Platform halves

`lib/resources/` and `lib/protocol/endpoints*.dart` are the only places that know whether they
run on a desktop or in a browser: a conditional `export` picks `platform_io.dart` or
`platform_web.dart`. Keep `dart:io` out of everything else, or `flutter build web` stops
compiling. Web views come from webview_flutter and exist only where it registered an
implementation (`hasWebView`), which is also why the test runner sees the text fallbacks.

## Faults

Never swallow a failure. Where the display survives by showing a fallback, call
`reportFault` from `lib/faults.dart` first; it goes through `FlutterError.onError`, so it is
in the log and a test fails unless it expects the report (`test/faults.dart` collects them).
Protocol faults are logged by the clients with the payload and stack.

## Verifying a change

A green test run proves the state machine and view models. A visible change needs the stack
running and eyes on the screen: ovos-visage's `docs/spike_say.py`, `tests/manual/demo.py`
and `tests/manual/show_templates.py` drive this app unchanged, on the desktop and in a browser
served by `tool/serve_web.py`. Paste what you saw in the PR.

## Pull Requests

1. Create a branch: `git checkout -b feat/my-change` or `fix/my-change`
2. Add tests for the change
3. Run `just lint` and `just test`
4. Open a pull request with a conventional commit title (`feat:`, `fix:`, `chore:`, `docs:`)

A maintainer merges. Releases are cut by release-please from the conventional commits.
