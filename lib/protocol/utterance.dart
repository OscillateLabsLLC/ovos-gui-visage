/// A typed command, sent the way `ovos-say-to` (ovos_bus_client/scripts.py) sends one: `recognizer_loop:utterance`
/// on the core bus with `utterances: [text]` and `lang`. With no language configured, `lang` is left out and ovos-core
/// answers in its own default (`get_message_lang` falls back to the session, then the configuration), so a typed
/// command can never switch OVOS to a language the user did not choose.
library;

import '../faults.dart';
import 'core_bus.dart';

const utteranceMessage = 'recognizer_loop:utterance';

Json utteranceData(String text, {String? lang}) => {
  'utterances': [text.trim()],
  if (lang != null && lang.isNotEmpty) 'lang': lang,
};

/// Sends [text] unless it is blank; a closed bus is reported, not dropped quietly. True when it left.
bool sendUtterance(CoreBus bus, String text, {String? lang}) {
  if (text.trim().isEmpty) return false;
  if (bus.emit(utteranceMessage, utteranceData(text, lang: lang))) return true;
  reportFault('sending a typed command', StateError('the core bus is not connected; "$text" was not sent'));
  return false;
}
