/// The language of the dates and clocks Visage draws itself (the device clock, `SYSTEM_clock`, the weather card's
/// weekdays): the configured `lang`, else the platform's language, through CLDR's names and patterns (`intl`).
/// Text a producer sends (`weekday_string`, `time_string`) is shown as sent and never passes through here.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'faults.dart';

const _fallback = 'en_US';

String _locale = _fallback;

/// The locale in use, as `intl` names it (`da`, `en_US`).
String get dateLocale => _locale;

/// Loads CLDR's date names and picks [tag] (`da-dk`, `pt-BR`), else [platform], else English.
Future<void> useDateLocale(String? tag, {String? platform}) async {
  await initializeDateFormatting();
  _locale = _verified(tag) ?? _verified(platform) ?? _fallback;
}

String? _verified(String? tag) {
  if (tag == null || tag.isEmpty) return null;
  final name = Intl.canonicalizedLocale(tag.replaceAll('-', '_'));
  final found = Intl.verifiedLocale(name, DateFormat.localeExists, onFailure: (_) => null);
  if (found == null) reportFault('date locale: no CLDR data for "$tag"', ArgumentError.value(tag, 'lang'));
  return found;
}

/// `Sunday, 25 October` in English, as Visage always drew it; other languages take CLDR's own weekday-day-month
/// pattern (`Søndag 25. oktober`), first letter raised to match.
String localDateLine(DateTime now) {
  if (_locale.startsWith('en')) return DateFormat('EEEE, d MMMM', _locale).format(now);
  return _capitalized(DateFormat.MMMMEEEEd(_locale).format(now));
}

/// `Mon`, `man.`: the short weekday name.
String localShortWeekday(DateTime day) => DateFormat.E(_locale).format(day);

/// The am/pm marker for [now] in the locale's words (`AM`, `PM`).
String localDayPeriod(DateTime now) => DateFormat('a', _locale).format(now);

/// Whether the locale writes a 24-hour clock: CLDR's hour-minute pattern has no day period.
bool localeUses24Hour() => !DateFormat.jm(_locale).pattern!.contains('a');

/// A browser has no 12/24-hour setting (`alwaysUse24HourFormat` is always false there), so the web build follows
/// the language's own clock; a desktop keeps the system setting.
bool deviceUses24Hour(BuildContext context) => kIsWeb ? localeUses24Hour() : MediaQuery.alwaysUse24HourFormatOf(context);

String _capitalized(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
