/// The window's title names the app, the GUI protocol and the window mode, so two Visage windows on one screen (the
/// GUI-1 demo beside the daily driver) can be told apart in the title bar, the Dock's window list and Mission Control.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../protocol/gui_link.dart';
import 'window_config.dart';
import 'window_remote.dart';

const titleAppName = 'Visage';
const _separator = ' · ';

/// `Visage · GUI-1 · window`. Before the probe decides, `auto` reads `detecting…`; `gui1` and `legacy` name their
/// protocol from the start. [windowMode] is null where there is no window to name (the browser tab).
String windowTitle(WireProtocol mode, ChosenProtocol? chosen, WindowMode? windowMode) {
  final protocol =
      chosen?.label ??
      switch (mode) {
        WireProtocol.auto => 'detecting…',
        WireProtocol.gui1 => ChosenProtocol.gui1.label,
        WireProtocol.legacy => ChosenProtocol.legacy.label,
      };
  return [titleAppName, protocol, ?windowMode?.name].join(_separator);
}

/// Calls [set] with [read] now and again whenever [changes] fires and the title differs from the last one set.
VoidCallback followTitle({required Listenable changes, required String Function() read, required void Function(String) set}) {
  String? last;
  void update() {
    final title = read();
    if (title == last) return;
    last = title;
    set(title);
  }

  update();
  changes.addListener(update);
  return () => changes.removeListener(update);
}

/// The title follows the chosen protocol and the window mode; [set] is `setWindowTitle` (window_shell.dart).
VoidCallback bindWindowTitle(GuiLink gui, WindowRemote window, Future<void> Function(String) set) => followTitle(
  changes: Listenable.merge([gui.title, window]),
  read: () => windowTitle(gui.mode, gui.chosen, kIsWeb ? null : window.config.mode),
  set: (title) => unawaited(set(title)),
);
