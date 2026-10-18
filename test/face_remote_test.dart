import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/face/composed_theme.dart';
import 'package:ovos_gui_visage/face/face.dart';
import 'package:ovos_gui_visage/face/face_remote.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/face/styles/line_mouths.dart';
import 'package:ovos_gui_visage/face/styles/shape_eyes.dart';

import 'faults.dart';
import 'recording_bus.dart';

void main() {
  late RecordingBus bus;
  late FaceController controller;
  late List<FaceSpec> saved;
  late FaceRemote remote;

  setUp(() {
    bus = RecordingBus();
    controller = FaceController();
    saved = [];
    remote = FaceRemote(bus, controller, initial: FaceSpec.parse('visage'), persist: (spec) async => saved.add(spec));
  });

  test('set changes the parts named, repaints the controller, saves and announces', () {
    bus.send(faceSetMessage, {'eyes': 'block', 'mouthSize': 'large'});
    expect(remote.spec, const FaceSpec(eyes: 'block', mouthSize: 'large'));
    final theme = controller.theme as ComposedTheme;
    expect(theme.eyeStyle, isA<BlockEyes>());
    expect(theme.mouthScale, 1.4);
    expect(saved, [const FaceSpec(eyes: 'block', mouthSize: 'large')]);
    expect(bus.types, [faceStateMessage]);
    expect(bus.data(0)!['eyes'], 'block');
    expect(bus.data(0)!['preset'], isNull);
  });

  test('a preset in the payload resets the pairing and keeps the size', () {
    bus.send(faceSetMessage, {'mouthSize': 'large'});
    bus.send(faceSetMessage, {'preset': 'retro'});
    expect(remote.spec, const FaceSpec(eyes: 'ring', mouth: 'waveform', mouthSize: 'large'));
    expect((controller.theme as ComposedTheme).mouthStyle, isA<WaveformMouth>());
    expect(bus.data(1)!['preset'], 'retro');
  });

  test('get answers with the state and what is available', () {
    bus.send(faceGetMessage);
    final state = bus.data(0)!;
    expect(state['eyes'], 'lens');
    expect(state['preset'], 'visage');
    expect((state['available'] as Map)['eyes'], contains('aperture'));
    expect((state['available'] as Map)['preset'], contains('mark1'));
  });

  test('a payload that is not an object is reported and ignored', () async {
    final faults = await collectFaults(() async => bus.handlers[faceSetMessage]!({'type': faceSetMessage, 'data': 'mark1'}));
    expect(faults, hasLength(1));
    expect(remote.spec, FaceSpec.visage);
    expect(saved, isEmpty);
  });

  test('a save that fails is reported, and the face still changed', () async {
    final failing = FaceRemote(
      RecordingBus(),
      controller,
      initial: FaceSpec.visage,
      persist: (_) async => throw StateError('disk full'),
    );
    final faults = await collectFaults(() async {
      failing.apply(FaceSpec.parse('pod'));
      await Future<void>.delayed(Duration.zero);
    });
    expect(faults, hasLength(1));
    expect(failing.spec.presetName, 'pod');
  });
}
