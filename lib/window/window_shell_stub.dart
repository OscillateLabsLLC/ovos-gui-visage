import '../app_config.dart';
import '../face/face_spec.dart';
import 'window_config.dart';

Future<AppConfig> loadAppConfig() async => const AppConfig();

/// The web build has no config file; a face chosen there lasts the page's lifetime, by design.
Future<void> saveFaceConfig(FaceSpec spec) async {}

Future<void> applyWindowConfig(WindowConfig config) async {}
