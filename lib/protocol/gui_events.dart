/// What a page sends back to OVOS on the GUI socket, in the shape mycroft-gui's `AbstractSkillView::triggerEvent`
/// sends. ovos-gui (bus.py `GUIWebsocketHandler.on_message`, 1.5.3a1) turns each into a core bus message:
///
/// - `page_gained_focus` becomes `gui.page_gained_focus` with `namespace`, `page_number` (from `parameters.number`)
///   and `skill_id` (from `parameters.skillId`); ovos-gui then focuses that page and echoes the event to every client.
/// - `system.gui.user.interaction` becomes `gui.page_interaction` with the same three keys, which restarts the
///   namespace's removal timer (and focuses `page_number` when one is given).
/// - Any other event becomes `<namespace>.<event_name>` with `parameters` as its data.
library;

import '../json.dart';

const eventsTriggered = 'mycroft.events.triggered';
const pageGainedFocus = 'page_gained_focus';
const userInteraction = 'system.gui.user.interaction';

/// mycroft-gui sends `system.*` events in the `system` namespace and every other event in the page's own namespace.
const systemEventNamespace = 'system';

Json guiEvent(String namespace, String eventName, [Json parameters = const {}]) => {
  'type': eventsTriggered,
  'namespace': eventName.startsWith('system.') ? systemEventNamespace : namespace,
  'event_name': eventName,
  'parameters': parameters,
};

/// ovos-gui reads `parameters` (not `data`) from client events and takes the namespace from `skillId`.
Json focusMessage(String namespace, int number) => guiEvent(namespace, pageGainedFocus, {'number': number, 'skillId': namespace});

/// What the Qt delegate sends on every press and key release inside a page, so a page in use does not time out.
Json interactionMessage(String namespace) => guiEvent(namespace, userInteraction, {'skillId': namespace});

/// The core bus message ovos-gui emits for [message], as bus.py builds it; tests and the fixtures check against it.
Json busMessageFor(Json message) {
  final name = message['event_name'] as String;
  final parameters = message['parameters'] as Json;
  if (name == pageGainedFocus || name == userInteraction) {
    return {
      'type': name == pageGainedFocus ? 'gui.page_gained_focus' : 'gui.page_interaction',
      'data': {'namespace': message['namespace'], 'page_number': parameters['number'], 'skill_id': parameters['skillId']},
    };
  }
  return {'type': '${message['namespace']}.$name', 'data': parameters};
}
