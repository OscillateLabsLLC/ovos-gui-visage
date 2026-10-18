import 'dart:io';

import 'package:flutter/services.dart';

import '../faults.dart';
import 'window_channel.dart';
import 'window_shell_io.dart';

const pickerAsset = 'docs/face-palettes.html';
const pickerFileName = 'faces.html';
const openUrlMethod = 'openUrl';

/// Writes the page bundled with the app beside the config file, every time so an upgraded app ships its own page,
/// and asks the runner to open it with the bus in the fragment. A failure is reported and never thrown.
Future<void> openFacePicker(Uri bus, {File? page}) async {
  final target = page ?? File('${configFile().parent.path}/$pickerFileName');
  try {
    final bytes = await rootBundle.load(pickerAsset);
    await target.create(recursive: true);
    await target.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
    await windowChannel.invokeMethod<void>(openUrlMethod, pickerUrl(target, bus));
  } on Object catch (err, stack) {
    reportFault('opening the face picker at ${target.path}', err, stack);
  }
}

/// `file:///…/faces.html#bus=ws://…`: the page reads the bus from the fragment, which survives where a query may not.
String pickerUrl(File page, Uri bus) => Uri.file(page.absolute.path).replace(fragment: 'bus=$bus').toString();
