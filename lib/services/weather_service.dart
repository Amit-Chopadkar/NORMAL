import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:math';

class WeatherService {
  static const String _apiKey =
      String.fromEnvironment('PIRATE_WEATHER_API_KEY', defaultValue: '');
  static const String _baseUrl = 'https://api.pirateweather.net/forecast';

  static Future<Map<String, dynamic>> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Pirate Weather API key missing. Pass --dart-define=PIRATE_WEATHER_API_KEY=your_key when running the app.',
      );
    }

    final url = Uri.parse(
      '$_baseUrl/$_apiKey/$latitude,$longitude'
      '?units=si&exclude=minutely,hourly,daily,alerts,flags',
    );

    final response = await http.get(url);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Pirate Weather request failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final currently =
        decoded['currently'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final weatherTime = (currently['time'] is num)
        ? DateTime.fromMillisecondsSinceEpoch(
            (currently['time'] as num).toInt() * 1000,
            isUtc: true,
          ).toLocal()
        : DateTime.now();

    return {
      'summary': (currently['summary'] ?? 'Unknown').toString(),
      'temperature': _asDouble(currently['temperature']),
      'apparentTemperature': _asDouble(
        currently['apparentTemperature'] ?? currently['temperature'],
      ),
      'humidity': _asDouble(currently['humidity']),
      'precipProbability': _asDouble(currently['precipProbability']),
      'windSpeed': _asDouble(currently['windSpeed']),
      'icon': (currently['icon'] ?? 'cloudy').toString(),
      'timestamp': weatherTime,
    };
  }

  static double _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0;
    }
    return 0;
  }

  /// Fetch current weather from OpenWeatherMap (simple helper).
  /// Uses the provided API key or the default embedded key.
  static const String _openWeatherDefaultKey = '4899269d440f1eb65dcc8bb0efbafc95';

  static Future<Map<String, dynamic>?> fetchOpenWeatherCurrent({
    required double latitude,
    required double longitude,
    String? apiKey,
  }) async {
    final key = apiKey ?? _openWeatherDefaultKey;
    try {
      final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'appid': key,
        'units': 'metric',
      });
      // Debug logging to help verify network calls on device
      try {
        // ignore: avoid_print
        print('WeatherService: OpenWeather request -> $uri');
      } catch (_) {}

      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      // Debug response log (truncate large bodies)
      try {
        final sample = resp.body.length > 500 ? resp.body.substring(0, 500) + '...' : resp.body;
        // ignore: avoid_print
        print('WeatherService: OpenWeather status=${resp.statusCode} body=${sample}');
      } catch (_) {}

      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final weatherList = data['weather'] as List<dynamic>?;
      final main = data['main'] as Map<String, dynamic>?;
      final desc = (weatherList != null && weatherList.isNotEmpty)
          ? (weatherList[0]['description'] as String?)?.toLowerCase() ?? ''
          : '';
      final icon = (weatherList != null && weatherList.isNotEmpty) ? weatherList[0]['icon'] as String? : null;
      final temp = main != null && main['temp'] != null ? (main['temp'] as num).toDouble() : null;
      final humidity = main != null && main['humidity'] != null ? (main['humidity'] as num).toDouble() : null;
      final windSpeed = (data['wind'] is Map && data['wind']['speed'] != null)
          ? (data['wind']['speed'] as num).toDouble()
          : null;
      // Approximate precipProbability: 1.0 if rain/snow block exists, otherwise 0.0
      final precipProbability = (data['rain'] != null || data['snow'] != null) ? 1.0 : 0.0;

      return {
        'description': desc,
        'temp': temp,
        'icon': icon,
        'humidity': humidity,
        'windSpeed': windSpeed,
        'precipProbability': precipProbability,
      };
    } catch (e) {
      return null;
    }
  }
}

