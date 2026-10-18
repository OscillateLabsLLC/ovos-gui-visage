import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/window/face_picker_io.dart';
import 'package:ovos_gui_visage/window/window_channel.dart';

import 'faults.dart';

final _bus = Uri.parse('ws://127.0.0.1:8181/core');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory dir;
  late List<MethodCall> calls;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('face_picker');
    calls = [];
    addTearDown(() => dir.deleteSync(recursive: true));
    addTearDown(() => messenger.setMockMethodCallHandler(windowChannel, null));
  });

  test('the URL is the file with the bus in the fragment', () {
    expect(pickerUrl(File('/a b/faces.html'), _bus), 'file:///a%20b/faces.html#bus=ws://127.0.0.1:8181/core');
  });

  test('writes the bundled page, overwriting an old one, and asks the runner to open it', () async {
    messenger.setMockMethodCallHandler(windowChannel, (call) async => calls.add(call));
    final page = File('${dir.path}/config/faces.html')
      ..createSync(recursive: true)
      ..writeAsStringSync('an older page');
    await openFacePicker(_bus, page: page);
    expect(page.readAsStringSync(), File('docs/face-palettes.html').readAsStringSync());
    expect(calls.single.method, openUrlMethod);
    expect(calls.single.arguments, pickerUrl(page, _bus));
  });

  test('a runner that cannot open it is reported, not thrown', () async {
    messenger.setMockMethodCallHandler(windowChannel, (call) async => throw PlatformException(code: 'open-failed'));
    final faults = await collectFaults(() => openFacePicker(_bus, page: File('${dir.path}/faces.html')));
    expect(faults.single.exception, isA<PlatformException>());
  });

  test('a page that cannot be written is reported, and nothing is opened', () async {
    messenger.setMockMethodCallHandler(windowChannel, (call) async => calls.add(call));
    final blocker = File('${dir.path}/file')..writeAsStringSync('');
    final faults = await collectFaults(() => openFacePicker(_bus, page: File('${blocker.path}/faces.html')));
    expect(faults.single.exception, isA<FileSystemException>());
    expect(calls, isEmpty);
  });
}
