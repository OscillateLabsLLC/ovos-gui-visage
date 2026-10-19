import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_shell_io.dart';

import 'faults.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test runner has no window plugin at all, so every call is missing: the widget setup must still reach the
  // placing and showing of the window. Measured on Linux: window_manager has no setHasShadow there, and the setup
  // used to stop at that call with the window never placed or shown.
  test('a missing window call is reported once and the widget is still placed and shown', () async {
    Future<void> start() => applyWindowConfig(const WindowConfig(mode: WindowMode.float, peek: true));

    final first = await collectFaults(start);
    final again = await collectFaults(start);
    final contexts = [for (final fault in first) '${fault.context}'];
    expect(contexts, contains('setHasShadow in widget setup'));
    expect(contexts, contains('setVisibleOnAllWorkspaces in widget setup'));
    expect(contexts, contains('setPosition in widget setup'));
    expect(contexts, contains('show in widget setup'));
    expect(contexts.toSet(), hasLength(contexts.length));
    expect([for (final fault in again) '${fault.context}'].where((c) => c.endsWith('in widget setup')), isEmpty);
  });

  test('a desktop widget takes the runner level on macOS and keep-below elsewhere', () async {
    final faults = await collectFaults(() => applyWindowConfig(const WindowConfig(mode: WindowMode.desktop)));
    final contexts = [for (final fault in faults) '${fault.context}'];
    final level = Platform.isMacOS
        ? 'setWindowLevel is not implemented by this platform runner'
        : 'setAlwaysOnBottom in widget setup';
    expect(contexts, contains(level));
  });
}
