import 'package:flutter/foundation.dart';
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
}
