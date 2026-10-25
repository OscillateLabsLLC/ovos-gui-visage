/// SYSTEM_map (gui-1.md §3.4, line 262): `latitude` and `longitude` (WGS-84, required), `zoom` (1–20), `label`. Visage
/// has no map provider yet, so the card is the §6.5 degradation: the label and the coordinates as text. Pure.
library;

import '../json.dart';
import 'data_faults.dart';

const latitudeRange = (min: -90.0, max: 90.0);
const longitudeRange = (min: -180.0, max: 180.0);
const zoomRange = (min: 1.0, max: 20.0);
const noLocation = 'Location unavailable';
const _coordinateDigits = 4;

typedef MapCard = ({String label, String coordinates, double? zoom, List<String> problems});

/// The type problem, else the range problem, else null. An absent optional key is fine.
String? _rangeProblem(Object? value, String key, ({double min, double max}) range, {bool required = true}) {
  final typeProblem = required ? requiredNumber(value, key) : optionalNumber(value, key);
  if (typeProblem != null || value == null) return typeProblem;
  final number = (value as num).toDouble();
  if (number >= range.min && number <= range.max) return null;
  return '$key must be between ${range.min} and ${range.max}, got $value';
}

String _hemisphere(double value, String positive, String negative) =>
    '${value.abs().toStringAsFixed(_coordinateDigits)}° ${value < 0 ? negative : positive}';

/// `29.4241° N, 98.4936° W`.
String coordinateLine(double latitude, double longitude) =>
    '${_hemisphere(latitude, 'N', 'S')}, ${_hemisphere(longitude, 'E', 'W')}';

MapCard mapCard(Json data) {
  final latitude = data['latitude'], longitude = data['longitude'], zoom = data['zoom'], label = data['label'];
  final latitudeProblem = _rangeProblem(latitude, 'latitude', latitudeRange);
  final longitudeProblem = _rangeProblem(longitude, 'longitude', longitudeRange);
  final zoomProblem = _rangeProblem(zoom, 'zoom', zoomRange, required: false);
  final placed = latitudeProblem == null && longitudeProblem == null;
  return (
    label: optionalText(label),
    coordinates: placed ? coordinateLine((latitude as num).toDouble(), (longitude as num).toDouble()) : '',
    zoom: zoomProblem == null ? finite(zoom) : null,
    problems: [latitudeProblem, longitudeProblem, zoomProblem, optionalString(label, 'label')].nonNulls.toList(),
  );
}
