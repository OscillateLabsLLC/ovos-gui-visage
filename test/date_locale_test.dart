import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/date_locale.dart';
import 'package:ovos_gui_visage/pages/clock_page.dart';
import 'package:ovos_gui_visage/pages/weather_card_model.dart';

import 'faults.dart';

double unix(DateTime at) => at.millisecondsSinceEpoch / 1000;

void main() {
  final evening = DateTime(2026, 10, 25, 21, 5);

  tearDown(() => useDateLocale(null));

  test('without a language the clock speaks English, as before', () async {
    await useDateLocale(null);
    expect(dateLocale, 'en_US');
    expect(clockView(evening, use24Hour: false), (time: '9:05', ampm: 'PM', date: 'Sunday, 25 October'));
    expect(localeUses24Hour(), isFalse);
  });

  test('a configured language names the day and month, and writes a 24-hour clock', () async {
    await useDateLocale('da-dk');
    expect(dateLocale, 'da');
    expect(clockView(evening, use24Hour: localeUses24Hour()), (time: '21:05', ampm: '', date: 'Søndag 25. oktober'));
    expect(periodLabel(unix(evening), hourly: false, use24Hour: true), 'søn.');
  });

  test('the configured language wins over the platform, and each language has its own words', () async {
    await useDateLocale('de-DE', platform: 'da-DK');
    expect(localDateLine(evening), 'Sonntag, 25. Oktober');
    await useDateLocale('es-ES');
    expect(localDateLine(evening), 'Domingo, 25 de octubre');
    expect(localeUses24Hour(), isTrue);
  });

  test('with no language configured, the platform language is used', () async {
    await useDateLocale(null, platform: 'fr-FR');
    expect(localDateLine(evening), 'Dimanche 25 octobre');
  });

  test('a language CLDR does not know is reported, and the next choice is used', () async {
    final faults = await collectFaults(() => useDateLocale('xx-YY', platform: 'nl-NL'));
    expect(faults.map((fault) => '${fault.context}'), ['date locale: no CLDR data for "xx-YY"']);
    expect(dateLocale, 'nl');
  });
}
