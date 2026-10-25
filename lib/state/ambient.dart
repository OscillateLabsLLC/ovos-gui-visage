/// Ambient data for the resting display (gui-1.md 6.9.1): the last `gui.ambient.*` payload per topic. It is not a
/// namespace and enters no stack, so a stack change, a snapshot or a reconnect leaves it as it was; only the next
/// message on the same topic replaces it.
library;

import '../json.dart';

const ambientPrefix = 'gui.ambient.';
const ambientWeather = 'gui.ambient.weather';
const ambientNotifications = 'gui.ambient.notifications';

bool isAmbientTopic(String topic) => topic.startsWith(ambientPrefix);

/// The keys gui-1.md 6.9.1 requires of [topic] that [data] lacks; empty for a topic the spec gives no keys to.
List<String> missingAmbientKeys(String topic, Json data) => switch (topic) {
  ambientWeather => [if (data['current_temp'] is! num) 'current_temp', if (data['condition'] is! String) 'condition'],
  ambientNotifications => [if (data['count'] is! num) 'count'],
  _ => const [],
};
