import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
import 'package:ovos_gui_visage/protocol/wire_protocol.dart';
import 'package:ovos_gui_visage/window/window_config.dart';

import 'faults.dart';

void main() {
  test('the face comes from the file as a name or an object, the environment wins, visage is the default', () {
    expect(AppConfig.from(null, const {}).face, FaceSpec.visage);
    expect(AppConfig.from({'face': 'Mark1'}, const {}).face.presetName, 'mark1');
    expect(AppConfig.from({'face': 'mark1'}, const {'VISAGE_FACE': 'visage'}).face, FaceSpec.visage);
    final object = AppConfig.from({
      'face': {'eyes': 'oval', 'mouth': 'none', 'mouthSize': 'large'},
    }, const {});
    expect(object.face, const FaceSpec(eyes: 'oval', mouth: 'none', mouthSize: 'large'));
    expect(
      AppConfig.from(null, const {'VISAGE_FACE': 'dot+bars+large'}).face,
      const FaceSpec(eyes: 'dot', mouth: 'bars', mouthSize: 'large'),
    );
  });

  test('the window object still reaches the window config', () {
    final config = AppConfig.from({
      'window': {'mode': 'float'},
    }, const {});
    expect(config.window.mode, WindowMode.float);
    final kiosk = AppConfig.from({
      'window': {'mode': 'kiosk'},
    }, const {});
    expect(kiosk.window.mode, WindowMode.kiosk);
    expect(kiosk.window.kioskExit, WindowMode.float);
  });

  test('motion is full by default; cut from the file or the environment, the environment winning', () {
    expect(AppConfig.from(null, const {}).motion, MotionSetting.full);
    expect(const AppConfig().motion, MotionSetting.full);
    expect(AppConfig.from({'motion': 'cut'}, const {}).motion, MotionSetting.cut);
    expect(AppConfig.from({'motion': 'cut'}, const {'VISAGE_MOTION': 'FULL'}).motion, MotionSetting.full);
    expect(AppConfig.from(null, const {'VISAGE_MOTION': ' cut '}).motion, MotionSetting.cut);
  });

  test('a motion value that is neither is reported and leaves motion full', () async {
    late AppConfig config;
    final faults = await collectFaults(() async => config = AppConfig.from(null, const {'VISAGE_MOTION': 'slow'}));
    expect(config.motion, MotionSetting.full);
    expect(faults.single.context.toString(), contains('config: motion'));
  });

  test('captions are off by default, on from the file or the environment, and the environment wins', () {
    expect(AppConfig.from(null, const {}).captions, isFalse);
    expect(const AppConfig().captions, isFalse);
    expect(AppConfig.from({'captions': true}, const {}).captions, isTrue);
    expect(AppConfig.from(null, const {'VISAGE_CAPTIONS': '1'}).captions, isTrue);
    expect(AppConfig.from({'captions': true}, const {'VISAGE_CAPTIONS': 'off'}).captions, isFalse);
  });

  test('a captions value that is not a flag is reported and keeps captions off', () async {
    late AppConfig config;
    final faults = await collectFaults(() async => config = AppConfig.from({'captions': 'loud'}, const {}));
    expect(config.captions, isFalse);
    expect(faults.single.context.toString(), contains('captions is not a flag'));
  });

  test('protocol is auto by default, from the file, and VISAGE_PROTOCOL wins', () {
    expect(AppConfig.from(null, const {}).protocol, WireProtocol.auto);
    expect(AppConfig.from({'protocol': 'legacy'}, const {}).protocol, WireProtocol.legacy);
    expect(AppConfig.from({'protocol': 'legacy'}, const {'VISAGE_PROTOCOL': 'gui1'}).protocol, WireProtocol.gui1);
  });

  test('an unknown protocol is reported and treated as auto', () async {
    late AppConfig config;
    final faults = await collectFaults(() async => config = AppConfig.from({'protocol': 'qt5'}, const {}));
    expect(config.protocol, WireProtocol.auto);
    expect(faults.single.exceptionAsString(), contains('qt5'));
  });

  test('VISAGE_GUI1_URL moves the GUI-1 endpoint; anything but a ws URL is reported and ignored', () async {
    expect(AppConfig.from(null, const {}).gui1Url, isNull);
    final url = AppConfig.from({'gui1Url': 'ws://a:1/gui1'}, const {'VISAGE_GUI1_URL': 'ws://127.0.0.1:28182/gui1'}).gui1Url;
    expect(url, Uri.parse('ws://127.0.0.1:28182/gui1'));
    late AppConfig config;
    final faults = await collectFaults(() async => config = AppConfig.from(null, const {'VISAGE_GUI1_URL': 'http://x/gui1'}));
    expect(config.gui1Url, isNull);
    expect(faults, hasLength(1));
  });
}
