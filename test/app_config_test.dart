import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/app_config.dart';
import 'package:ovos_gui_visage/face/face_spec.dart';
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

  test('captions are on by default, off from the file or the environment, and the environment wins', () {
    expect(AppConfig.from(null, const {}).captions, isTrue);
    expect(AppConfig.from({'captions': false}, const {}).captions, isFalse);
    expect(AppConfig.from(null, const {'VISAGE_CAPTIONS': 'off'}).captions, isFalse);
    expect(AppConfig.from({'captions': false}, const {'VISAGE_CAPTIONS': '1'}).captions, isTrue);
  });

  test('a captions value that is not a flag is reported and keeps captions on', () async {
    late AppConfig config;
    final faults = await collectFaults(() async => config = AppConfig.from({'captions': 'loud'}, const {}));
    expect(config.captions, isTrue);
    expect(faults.single.context.toString(), contains('captions is not a flag'));
  });
}
