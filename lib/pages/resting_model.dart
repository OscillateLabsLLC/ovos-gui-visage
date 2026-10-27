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

/// How long a `gui.ambient.weather` payload is shown, counted from its arrival. A producer that is alive sends a fresh
/// one well inside this; after it the clock stands alone rather than showing a morning's sun at midnight.
const restingWeatherLife = Duration(hours: 3);

const _nightFrom = 20;
const _nightUntil = 6;

/// Night by the device clock, for the icon alone: `condition_code` has no day or night variant and `SYSTEM_weather`
/// carries no sunrise or sunset (docs/GUI1_FINDINGS.md F53), so the hour is the only cue.
bool isNightAt(DateTime now) => now.hour >= _nightFrom || now.hour < _nightUntil;

/// The icon for [code]; a clear sky at night is the night icon.
String? conditionIcon(Object? code, {required bool night}) => code == 'clear' && night ? 'night' : conditionIcons[code];

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

/// The weather chip at [now], or null while no complete `gui.ambient.weather` has arrived, or the last one arrived at
/// [keptAt] more than [restingWeatherLife] ago. A null [keptAt] is a payload of unknown age, and it shows.
RestingWeather? restingWeather(Map<String, Json> ambient, {required DateTime now, DateTime? keptAt}) {
  final data = ambient[ambientWeather];
  if (data == null || missingAmbientKeys(ambientWeather, data).isNotEmpty) return null;
  if (keptAt != null && now.difference(keptAt) > restingWeatherLife) return null;
  return (
    temperature: degrees(data['current_temp']),
    condition: text(data['condition']),
    icon: conditionIcon(data['condition_code'], night: isNightAt(now)),
  );
}
