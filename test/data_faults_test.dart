import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/data_faults.dart';

import 'faults.dart';

Widget reporter(List<String> problems) =>
    ReportsDataFaults(template: 'SYSTEM_x', problems: problems, child: const SizedBox.shrink());

void main() {
  test('type checks name the key and what arrived', () {
    expect(
      [requiredString('a', 'k'), requiredNumber(1, 'k'), optionalNumber(null, 'k'), optionalBool(true, 'k')],
      [null, null, null, null],
    );
    expect(requiredString(null, 'k'), 'k is required');
    expect(optionalString(3, 'k'), 'k must be a string, got int 3');
    expect(requiredNumber(double.nan, 'k'), 'k must be a finite number, got double NaN');
    expect(optionalBool('no', 'k'), 'k must be a boolean, got String no');
    expect([finite(2), finite('2'), finite(double.infinity)], [2.0, null, null]);
    expect([optionalText('x'), optionalText(4)], ['x', '']);
  });

  testWidgets('each problem is reported when it appears, not on every rebuild', (tester) async {
    final faults = await collectFaults(() async {
      await tester.pumpWidget(reporter(const ['a is required']));
      await tester.pumpWidget(reporter(const ['a is required']));
      await tester.pumpWidget(reporter(const []));
      await tester.pumpWidget(reporter(const ['b is required']));
    });
    expect(faults.map((f) => '${f.exception}'), ['FormatException: a is required', 'FormatException: b is required']);
    expect(faults.first.context?.toDescription(), 'SYSTEM_x data');
  });
}
