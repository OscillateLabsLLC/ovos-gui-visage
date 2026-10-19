import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../faults.dart';
import 'window_channel.dart';
import 'window_shell_io.dart';

const pickerAsset = 'docs/face-palettes.html';
const pickerFileName = 'faces.html';
const launcherFileName = 'open-faces.html';
const openUrlMethod = 'openUrl';

/// Writes the page bundled with the app beside the config file, every time so an upgraded app ships its own page,
/// and a launcher beside it, then opens the launcher in the browser. A failure is reported and never thrown.
Future<void> openFacePicker(Uri bus, {Directory? dir}) async {
  final target = dir ?? configFile().parent;
  try {
    final bytes = await rootBundle.load(pickerAsset);
    await target.create(recursive: true);
    await File('${target.path}/$pickerFileName').writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    final launcher = File('${target.path}/$launcherFileName');
    await launcher.writeAsString(launcherHtml(bus));
    await _open(Uri.file(launcher.absolute.path));
  } on Object catch (err, stack) {
    reportFault('opening the face picker in ${target.path}', err, stack);
  }
}

/// The runner opens it on macOS; elsewhere the desktop's default browser does, through xdg-open.
Future<void> _open(Uri page) async {
  if (Platform.isMacOS) return windowChannel.invokeMethod<void>(openUrlMethod, page.toString());
  final result = await Process.run('xdg-open', [page.toString()]);
  if (result.exitCode != 0) throw ProcessException('xdg-open', [page.toString()], '${result.stderr}'.trim(), result.exitCode);
}

/// macOS drops the fragment of a file URL it hands to the browser, so the runner opens this page without one and the
/// browser itself moves on to `faces.html#bus=ws://…`, where the picker reads the bus.
String launcherHtml(Uri bus) {
  final next = const HtmlEscape(HtmlEscapeMode.attribute).convert('$pickerFileName#bus=$bus');
  return '<!doctype html>\n<meta charset="utf-8">\n<title>Choose a face</title>\n'
      '<meta http-equiv="refresh" content="0; url=$next">\n<a href="$next">Open the face picker</a>\n';
}
