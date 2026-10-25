import 'package:flutter_test/flutter_test.dart';
import 'package:ovos_gui_visage/pages/spec_weather.dart';

const full = {
  'current_temp': 21,
  'min_temp': 14,
  'max_temp': 25.5,
  'condition': 'Despejado',
  'condition_code': 'clear',
  'location': 'San Antonio',
  'forecast': [
    {'time': 100, 'min_temp': 15, 'max_temp': 27, 'condition_code': 'rain'},
    {'time': 200},
  ],
};

void main() {
  test('every key reads, with no problems', () {
    final weather = specWeather(full);
    expect([weather.currentTemp, weather.minTemp, weather.maxTemp], [21.0, 14.0, 25.5]);
    expect(
      [weather.condition, weather.code, weather.location, weather.icon],
      ['Despejado', ConditionCode.clear, 'San Antonio', null],
    );
    expect(weather.forecast, [
      (time: 100.0, minTemp: 15.0, maxTemp: 27.0, code: ConditionCode.rain),
      (time: 200.0, minTemp: null, maxTemp: null, code: null),
    ]);
    expect(weather.problems, isEmpty);
  });

  test('the closed condition_code set, by wire name', () {
    final wire = ['clear', 'partly_cloudy', 'cloudy', 'fog', 'drizzle', 'rain', 'snow', 'sleet', 'thunder', 'wind'];
    expect([for (final code in ConditionCode.values) code.wire], wire);
    expect(ConditionCode.fromWire('partly_cloudy'), ConditionCode.partlyCloudy);
  });

  test('missing optional keys are absent without a problem', () {
    final weather = specWeather({'current_temp': -3, 'condition': 'Snow'});
    expect([weather.minTemp, weather.maxTemp, weather.code, weather.icon, weather.location], [null, null, null, null, '']);
    expect([weather.forecast, weather.problems], [isEmpty, isEmpty]);
  });

  test('missing required keys and wrong types are problems; the rest still reads', () {
    final weather = specWeather({'min_temp': '14', 'location': 'Austin'});
    expect(weather.problems, [
      'current_temp is required',
      'min_temp must be a finite number, got String 14',
      'condition is required',
    ]);
    expect([weather.currentTemp, weather.minTemp, weather.location], [null, null, 'Austin']);
  });

  test('an unlisted condition_code is reported and treated as absent', () {
    final weather = specWeather({...full, 'condition_code': 'hurricane'});
    expect(weather.code, isNull);
    expect(weather.problems.single, 'condition_code "hurricane" is not in the closed set, so it is ignored');
    expect(specWeather({...full, 'condition_code': 3}).problems.single, 'condition_code must be a string, got int 3');
  });

  test('icon: http(s) or data:image is kept; a bare path or a non-string is a problem', () {
    expect(specWeather({...full, 'icon': 'https://x/sun.png'}).icon, 'https://x/sun.png');
    expect(specWeather({...full, 'icon': 'data:image/png;base64,AA=='}).icon, 'data:image/png;base64,AA==');
    final path = specWeather({...full, 'icon': '/opt/skill/sun.png'});
    expect([path.icon, path.problems.single], [null, 'icon must be an http(s) URL or a data:image URI, got /opt/skill/sun.png']);
    expect(specWeather({...full, 'icon': 4}).problems.single, 'icon must be a string, got int 4');
  });

  test('forecast: bad entries are reported, the usable ones kept', () {
    final weather = specWeather({
      ...full,
      'forecast': [
        {'time': 300, 'condition_code': 'monsoon'},
        'tomorrow',
        {'max_temp': 20},
        {'time': 200, 'min_temp': 'cold'},
      ],
    });
    expect(weather.forecast.map((entry) => entry.time), [300.0, 200.0]);
    expect(weather.problems, [
      'forecast[0].condition_code "monsoon" is not in the closed set, so it is ignored',
      'forecast[1] must be an object, got String',
      'forecast[2].time is required',
      'forecast[3].min_temp must be a finite number, got String cold',
      'forecast is not in time order',
    ]);
    expect(specWeather({...full, 'forecast': 'sunny'}).problems.single, 'forecast must be an array, got String');
  });
}
