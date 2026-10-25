/// What Visage sends the GUI-1 adapter after `welcome` (WIRE.md, client → server frames; gui-1.md amendments A and B
/// as drafted). A page answers through [PageContext.trigger] in the legacy event shape whichever protocol is up; on
/// GUI-1 [gui1FrameFor] turns that event into the frame the adapter forwards, so nothing goes on the core bus.
library;

import '../json.dart';
import 'gui_events.dart';

/// The adapter emits it as the bus Message `gui.interaction`, with this client's session in the context.
Json interactionFrame(String namespace, String event, [Json data = const {}]) => {
  'type': 'interaction',
  'namespace': namespace,
  'event': event,
  'data': data,
};

/// The adapter emits it as `gui.page.focus`; the GUI service makes [pageNumber] the namespace's active entry, and a
/// focus on the entry already active only resets the namespace's timeout.
Json focusFrame(String namespace, int pageNumber) => {'type': 'focus', 'namespace': namespace, 'page_number': pageNumber};

/// The GUI-1 frame for a page event built by gui_events.dart: a focus change becomes `focus`, any other event in a
/// page's namespace becomes `interaction`. A touch ([userInteraction]) names no entry, so it has no frame: null.
/// `ScreenInput.interact` sends the touch as a `focus` on the known entry itself.
Json? gui1FrameFor(Json event) {
  final name = event['event_name'] as String;
  final parameters = event['parameters'] as Json;
  return switch (name) {
    pageGainedFocus => focusFrame(parameters['skillId'] as String, parameters['number'] as int),
    userInteraction => null,
    _ => interactionFrame(event['namespace'] as String, name, parameters),
  };
}
