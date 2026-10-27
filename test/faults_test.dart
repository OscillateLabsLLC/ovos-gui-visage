import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/faults.dart';

import 'faults.dart';

void main() {
  test('a reported fault prints as one line with its context and exception', () async {
    final faults = await collectFaults(() async => reportFault('the tray item', StateError('no watcher')));
    expect(faultLine(faults.single), 'ovos-gui-visage: fault in the tray item: Bad state: no watcher');
  });

  test('an error without a context still prints its library and exception', () {
    expect(faultLine(FlutterErrorDetails(exception: ArgumentError('x'))), 'Flutter framework: fault: Invalid argument(s): x');
  });

  test('a debug build off the web hands the framework report to the VM service only, not to the console (F36)', () {
    expect(kDebugMode && !kIsWeb, isTrue, reason: 'the test runner is a debug VM, as the live debug build was');
    expect(WidgetInspectorService.instance.isStructuredErrorsEnabled(), isTrue);
  });

  test('logFaultsPlainly prints every fault as a line, also when the framework report goes only to the VM service (F36)', () {
    final printed = <String>[];
    final presented = <FlutterErrorDetails>[];
    final (onError, presentError, print) = (FlutterError.onError, FlutterError.presentError, debugPrint);
    FlutterError.onError = FlutterError.presentError = presented.add;
    debugPrint = (message, {wrapWidth}) => printed.add(message ?? '');
    try {
      logFaultsPlainly();
      reportFault('SYSTEM_text data', const FormatException('text is required'));
    } finally {
      FlutterError.onError = onError;
      FlutterError.presentError = presentError;
      debugPrint = print;
    }
    expect(printed.take(1), ['ovos-gui-visage: fault in SYSTEM_text data: FormatException: text is required']);
    expect(presented, hasLength(1), reason: 'a debug build still gives Flutter its own report, for the IDE');
  });
}
