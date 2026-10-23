import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/widget_placement.dart';
import 'package:ovos_gui_visage/window/window_config.dart';
import 'package:ovos_gui_visage/window/window_drag_io.dart';

import 'faults.dart';

const _float = WindowConfig(mode: WindowMode.float);
const _desktop = WindowConfig(mode: WindowMode.desktop);
const _settle = Duration(milliseconds: 5);

Future<List<Corner>> _dropOn(DisplayBackend backend, {required List<String> reads}) async {
  final corners = <Corner>[];
  final drag = WindowDrag(
    config: () => _float,
    onCorner: corners.add,
    settleAfter: _settle,
    placement: () async => WidgetPlacement(backend),
    readDrop: () async {
      reads.add('read');
      return Corner.bottomLeft;
    },
  );
  await collectFaults(() async {
    drag.start();
    await Future<void>.delayed(_settle * 10);
  });
  return corners;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the runner names the backend; an unknown name is other', () {
    expect(DisplayBackend.named('x11'), DisplayBackend.x11);
    expect(DisplayBackend.named('wayland'), DisplayBackend.wayland);
    expect(DisplayBackend.named('broadway'), DisplayBackend.other);
    expect(DisplayBackend.named(null), DisplayBackend.other);
  });

  test('only native Wayland cannot place or snap a widget', () {
    for (final backend in DisplayBackend.values) {
      final placement = WidgetPlacement(backend);
      expect(placement.placesWidgets, backend != DisplayBackend.wayland, reason: backend.name);
      expect(placement.snapsAfterDrag, placement.placesWidgets, reason: backend.name);
    }
  });

  test('native Wayland reports a widget once per run, and never an ordinary window or kiosk', () {
    final placement = WidgetPlacement(DisplayBackend.wayland);
    expect(placement.takeReport(const WindowConfig(mode: WindowMode.window)), isFalse);
    expect(placement.takeReport(const WindowConfig(mode: WindowMode.kiosk)), isFalse);
    expect(placement.takeReport(_float), isTrue);
    expect(placement.takeReport(_desktop), isFalse);
    expect(placement.takeReport(_float), isFalse);
  });

  test('X11 and other backends never report', () {
    expect(WidgetPlacement(DisplayBackend.x11).takeReport(_float), isFalse);
    expect(WidgetPlacement(DisplayBackend.other).takeReport(_desktop), isFalse);
  });

  test('a drop on X11 snaps to the nearest corner', () async {
    final reads = <String>[];
    expect(await _dropOn(DisplayBackend.x11, reads: reads), [Corner.bottomLeft]);
    expect(reads, hasLength(1));
  });

  // Measured on KWin 5.27 native Wayland: the position reads as 0,0, so every drop saved topLeft.
  test('a drop on native Wayland neither reads the window back nor saves a corner', () async {
    final reads = <String>[];
    expect(await _dropOn(DisplayBackend.wayland, reads: reads), isEmpty);
    expect(reads, isEmpty);
  });
}
