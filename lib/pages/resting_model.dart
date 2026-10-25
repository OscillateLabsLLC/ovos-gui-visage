/// What the GUI-1 resting display shows from the kept ambient data (gui-1.md 6.9.1). Pure.
library;

import '../protocol/wire_protocol.dart';
import '../state/ambient.dart';
import '../state/gui_state.dart';
import 'page.dart';
import 'weather_model.dart';

/// `condition_code` (gui-1.md 3.4) to the bundled weather icons; a code outside the list has no icon, as if absent.
const conditionIcons = {
  'clear': 'sun',
  'partly_cloudy': 'partial_clouds',
  'cloudy': 'clouds',
  'fog': 'fog',
  'drizzle': 'rain',
  'rain': 'rain',
  'snow': 'snow',
  'sleet': 'snow',
  'thunder': 'storm',
  'wind': 'clouds',
};

typedef RestingWeather = ({String temperature, String condition, String? icon});

/// On GUI-1 the render backend owns the resting display (gui-1.md 6.9), so an empty stack shows Visage's own page. On legacy
/// the homescreen skill's idle page is the resting display, and the blank page stands in until it arrives.
bool showsResting(GuiState state, ChosenProtocol? protocol) => protocol == ChosenProtocol.gui1 && state.current() == null;

/// The pending-notification count from `gui.ambient.notifications`; 0 until one arrives (0 also means none).
int restingNotificationCount(Map<String, Json> ambient) {
  final data = ambient[ambientNotifications];
  if (data == null || missingAmbientKeys(ambientNotifications, data).isNotEmpty) return 0;
  return (data['count'] as num).toInt();
}

/// The weather chip, or null while no complete `gui.ambient.weather` has arrived.
RestingWeather? restingWeather(Map<String, Json> ambient) {
  final data = ambient[ambientWeather];
  if (data == null || missingAmbientKeys(ambientWeather, data).isNotEmpty) return null;
  return (
    temperature: degrees(data['current_temp']),
    condition: text(data['condition']),
    icon: conditionIcons[data['condition_code']],
  );
}
