import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_palette.dart';
import 'package:ovos_gui_visage/face/face_remote.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/window/peek.dart';
import 'package:ovos_gui_visage/window/status_menu.dart';
import 'package:ovos_gui_visage/window/status_menu_binding.dart';
import 'package:ovos_gui_visage/window/status_menu_host.dart';
import 'package:ovos_gui_visage/window/window_channel.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_remote.dart';

import 'faults.dart';
import 'manual_timers.dart';
import 'recording_bus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('binding', () {
    late RecordingBus bus;
    late FaceRemote face;
    late WindowRemote window;
    late List<List<MenuEntry>> shown;
    late StatusMenuController menu;
    var quits = 0;
    var pickers = 0;

    setUp(() {
      bus = RecordingBus();
      face = FaceRemote(bus, FaceController(), initial: FaceSpec.visage, persist: (_) async {}, picker: () async => pickers++);
      const config = WindowConfig(mode: WindowMode.float, peek: true);
      final peek = PeekController(enabled: true, timer: ManualTimers().create);
      const effects = WindowEffects(mode: _noMode, visible: _noVisible);
      window = WindowRemote(bus, peek, initial: config, persist: (_) async {}, effects: effects);
      shown = [];
      menu = bindStatusMenu(face: face, faceController: face.controller, window: window, show: shown.add, quit: () => quits++);
    });

    test('menu choices act through the remotes, which announce them, and the menu follows', () {
      menu.dispatch('face.mark1');
      menu.dispatch('colours.ice');
      menu.dispatch(desktopItem);
      menu.dispatch(visibleItem);
      menu.dispatch(peekItem);
      menu.dispatch(pickerItem);
      menu.dispatch(quitItem);
      expect(face.spec.presetName, 'mark1');
      expect(face.spec.colours, FacePalette.ice);
      expect(window.config.mode, WindowMode.desktop);
      expect(window.visible, isFalse);
      expect(window.config.peek, isFalse);
      expect(quits, 1);
      expect(pickers, 1);
      expect(bus.types.toSet(), {faceStateMessage, windowStateMessage});
      expect(shown, hasLength(6));
      expect(shown.last.first.title, 'Show face');
    });

    test('a change over the bus rebuilds the menu', () {
      bus.send(faceSetMessage, {'preset': 'robot'});
      bus.send(windowSetMessage, {'visible': false});
      expect(shown, hasLength(3));
      expect(shown.last.firstWhere((i) => i.id == 'face').children.where((c) => c.checked).single.id, 'face.robot');
    });
  });

  group('host', () {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    test('a runner without the menu is reported once, not on every rebuild', () async {
      final host = StatusMenuHost(onSelected: (_) {});
      final faults = await collectFaults(() async {
        host.show(const [MenuEntry(quitItem, 'Quit')]);
        host.show(const [MenuEntry(quitItem, 'Quit')]);
        await pumpEventQueue();
      });
      expect(faults.single.exception, isA<MissingPluginException>());
    });

    test('sends the items as JSON and hands a selection back', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(windowChannel, (call) async => calls.add(call));
      addTearDown(() => messenger.setMockMethodCallHandler(windowChannel, null));
      final selected = <String>[];
      StatusMenuHost(onSelected: selected.add).show(const [MenuEntry(quitItem, 'Quit')]);
      await pumpEventQueue();
      expect(calls.single.method, 'setMenu');
      expect(calls.single.arguments, [
        {'id': 'quit', 'title': 'Quit', 'checked': false, 'enabled': true},
      ]);
      await _fromRunner(messenger, const MethodCall('menuSelected', 'quit'));
      expect(selected, ['quit']);
    });

    test('an unknown call from the runner is reported', () async {
      StatusMenuHost(onSelected: (_) => fail('nothing is selected'));
      final faults = await collectFaults(() => _fromRunner(messenger, const MethodCall('menuSelected', 3)));
      expect(faults, hasLength(1));
    });
  });
}

Future<void> _noMode(WindowConfig config, {required WindowMode from, required bool expanded}) async {}

Future<void> _noVisible(bool visible) async {}

Future<void> _fromRunner(TestDefaultBinaryMessenger messenger, MethodCall call) =>
    messenger.handlePlatformMessage(windowChannel.name, windowChannel.codec.encodeMethodCall(call), (_) {});
