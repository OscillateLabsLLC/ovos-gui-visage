import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/map_card_model.dart';
import 'package:ovos_gui_visage/pages/map_page.dart';
import 'package:ovos_gui_visage/pages/router.dart';
import 'package:ovos_gui_visage/state/gui_state.dart';

import 'faults.dart';
import 'gui1_fixture.dart';

const places = 'ovos-skill-places.openvoiceos';

Future<List<String>> pumpFaults(WidgetTester tester, Json data) async {
  final state = replayGui1([template(places, 'SYSTEM_map', data)]);
  final faults = await collectFaults(() async => tester.pumpWidget(host(pageOf(state))));
  return [for (final fault in faults) '${fault.exception}'];
}

void main() {
  group('model', () {
    test('label, coordinates with hemispheres, zoom; no problems', () {
      final card = mapCard({'latitude': 29.4252, 'longitude': -98.4946, 'zoom': 12, 'label': 'The Alamo'});
      expect([card.label, card.coordinates, card.zoom, card.problems], ['The Alamo', '29.4252° N, 98.4946° W', 12.0, isEmpty]);
      expect(coordinateLine(-33.8688, 151.2093), '33.8688° S, 151.2093° E');
      expect(mapCard({'latitude': 90, 'longitude': -180}).problems, isEmpty);
    });

    test('a missing optional key is left out without a problem', () {
      final card = mapCard({'latitude': 0, 'longitude': 0});
      expect([card.label, card.coordinates, card.zoom, card.problems], ['', '0.0000° N, 0.0000° E', null, isEmpty]);
    });

    test('a missing or mistyped coordinate is a problem and hides the coordinates', () {
      final card = mapCard({'longitude': '98', 'label': 'Somewhere'});
      expect(card.problems, ['latitude is required', 'longitude must be a finite number, got String 98']);
      expect([card.label, card.coordinates], ['Somewhere', '']);
    });

    test('an out-of-range coordinate or zoom is a problem', () {
      final card = mapCard({'latitude': 91, 'longitude': 10, 'zoom': 0});
      expect(card.problems, ['latitude must be between -90.0 and 90.0, got 91', 'zoom must be between 1.0 and 20.0, got 0']);
      expect([card.coordinates, card.zoom], ['', null]);
      expect(mapCard({'latitude': 1, 'longitude': -180.5}).problems.single, startsWith('longitude must be between'));
    });
  });

  testWidgets('system_map fixture: the card shows the label, the placeholder and the coordinates', (tester) async {
    final state = replayGui1(loadGui1Fixture('system_map'));
    expect(state.current(), const Target(places, 'SYSTEM_map', 0));
    expect(resolve(state.current(), gaps: TemplateGaps()), same(MapPage.page));
    await tester.pumpWidget(host(pageOf(state)));
    expect([find.text('The Alamo'), find.text('29.4252° N, 98.4946° W')], everyElement(findsOneWidget));
    expect(find.byIcon(Icons.place), findsOneWidget);
  });

  testWidgets('an out-of-range latitude is reported and the label still shows', (tester) async {
    final faults = await pumpFaults(tester, {'latitude': 120, 'longitude': 10, 'label': 'Nowhere'});
    expect(faults, ['FormatException: latitude must be between -90.0 and 90.0, got 120']);
    expect(find.text('Nowhere'), findsOneWidget);
    expect(find.textContaining('°'), findsNothing);
  });

  testWidgets('no usable key at all: reported, and the card says the location is unavailable', (tester) async {
    final faults = await pumpFaults(tester, {});
    expect(faults, ['FormatException: latitude is required', 'FormatException: longitude is required']);
    expect(find.text(noLocation), findsOneWidget);
  });
}
