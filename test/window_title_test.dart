import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_title.dart';

void main() {
  test('the title names the app, the protocol and the mode', () {
    expect(windowTitle(WireProtocol.gui1, ChosenProtocol.gui1, WindowMode.window), 'Visage · GUI-1 · window');
    expect(windowTitle(WireProtocol.auto, ChosenProtocol.legacy, WindowMode.desktop), 'Visage · legacy · desktop');
    expect(windowTitle(WireProtocol.legacy, null, WindowMode.kiosk), 'Visage · legacy · kiosk');
  });

  test('before the probe decides, auto says so and gui1 already names itself', () {
    expect(windowTitle(WireProtocol.auto, null, WindowMode.float), 'Visage · detecting… · float');
    expect(windowTitle(WireProtocol.gui1, null, WindowMode.window), 'Visage · GUI-1 · window');
  });

  test('with no window to name, the title drops the mode', () {
    expect(windowTitle(WireProtocol.auto, ChosenProtocol.gui1, null), 'Visage · GUI-1');
  });

  test('the title is set at once, again on each change that alters it, and not after unbinding', () {
    final chosen = ValueNotifier<ChosenProtocol?>(null);
    final mode = ValueNotifier(WindowMode.window);
    final set = <String>[];
    final unbind = followTitle(
      changes: Listenable.merge([chosen, mode]),
      read: () => windowTitle(WireProtocol.auto, chosen.value, mode.value),
      set: set.add,
    );
    chosen.value = ChosenProtocol.gui1;
    mode.value = WindowMode.kiosk;
    mode.notifyListeners();
    unbind();
    mode.value = WindowMode.desktop;
    expect(set, ['Visage · detecting… · window', 'Visage · GUI-1 · window', 'Visage · GUI-1 · kiosk']);
  });
}
