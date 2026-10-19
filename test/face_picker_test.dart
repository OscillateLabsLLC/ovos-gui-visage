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
    dir = Directory.systemTemp.createTempSync('face picker');
    calls = [];
    addTearDown(() => dir.deleteSync(recursive: true));
    addTearDown(() => messenger.setMockMethodCallHandler(windowChannel, null));
  });

  test('the launcher moves on to the page with the bus in the fragment, escaped for the attribute', () {
    expect(launcherHtml(_bus), contains('content="0; url=faces.html#bus=ws://127.0.0.1:8181/core"'));
    expect(launcherHtml(Uri.parse('ws://h:1/core?a="b"&c')), contains('url=faces.html#bus=ws://h:1/core?a=%22b%22&amp;c"'));
  });

  test('the launcher has the picker page\'s own title', () {
    final title = RegExp('<title>[^<]*</title>');
    final page = File(pickerAsset).readAsStringSync();
    expect(title.firstMatch(launcherHtml(_bus))?.group(0), title.firstMatch(page)?.group(0));
    expect(launcherHtml(_bus), contains('<title>Choose a face</title>'));
  });

  test('writes the bundled page over an old one and the launcher, and opens the launcher', () async {
    final opened = <Uri>[];
    final config = Directory('${dir.path}/config');
    File('${config.path}/$pickerFileName')
      ..createSync(recursive: true)
      ..writeAsStringSync('an older page');
    await openFacePicker(_bus, dir: config, open: (page) async => opened.add(page));
    expect(File('${config.path}/$pickerFileName').readAsStringSync(), File('docs/face-palettes.html').readAsStringSync());
    expect(File('${config.path}/$launcherFileName').readAsStringSync(), launcherHtml(_bus));
    expect(opened.single, Uri.file('${config.path}/$launcherFileName'));
    expect('${opened.single}', contains('face%20picker'));
  });

  test('a browser that cannot open it is reported, not thrown', () async {
    final faults = await collectFaults(
      () => openFacePicker(_bus, dir: dir, open: (page) async => throw const ProcessException('xdg-open', [], 'no browser', 3)),
    );
    expect(faults.single.exception, isA<ProcessException>());
  });

  test('on macOS the runner opens the page', () async {
    messenger.setMockMethodCallHandler(windowChannel, (call) async => calls.add(call));
    await openInBrowser(Uri.file('/tmp/open-faces.html'));
    expect(calls.single.method, openUrlMethod);
    expect(calls.single.arguments, 'file:///tmp/open-faces.html');
  }, skip: !Platform.isMacOS);

  test('a page that cannot be written is reported, and nothing is opened', () async {
    final opened = <Uri>[];
    final blocker = File('${dir.path}/file')..writeAsStringSync('');
    final faults = await collectFaults(
      () => openFacePicker(_bus, dir: Directory(blocker.path), open: (page) async => opened.add(page)),
    );
    expect(faults.single.exception, isA<FileSystemException>());
    expect(opened, isEmpty);
  });
}
