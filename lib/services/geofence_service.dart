import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';

class GeofenceService {
  static const String boxName = 'geofenceBox';
  static final List<Function(Map)> _alertListeners = [];

  // Define restricted zones (can be fetched from API)
  static final List<Map<String, dynamic>> restrictedZones = [
    {
      'id': 1,
      'name': 'Remote Forest',
      'lat': 20.0112,
      'lng': 73.7909,
      'radius': 2000, // meters
      'riskLevel': 'high',
      'color': 'red',
    },
    {
      'id': 2,
      'name': 'Market Area',
      'lat': 20.0150,
      'lng': 73.7950,
      'radius': 800,
      'riskLevel': 'medium',
      'color': 'orange',
    },
    {
      'id': 3,
      'name': 'Industrial Zone',
      'lat': 20.0050,
      'lng': 73.7850,
      'radius': 1500,
      'riskLevel': 'high',
      'color': 'red',
    },
  ];

  static Future<void> initGeofence() async {
    await Hive.openBox(boxName);
  }

  // Check if current location is within restricted zone
  static Future<Map<String, dynamic>?> checkGeofence(
    double latitude,
    double longitude,
  ) async {
    try {
      for (var zone in restrictedZones) {
        double distance = _calculateDistance(
          latitude,
          longitude,
          zone['lat'],
          zone['lng'],
        );

        if (distance <= zone['radius']) {
          return {
            'alert': true,
            'zone': zone['name'],
            'riskLevel': zone['riskLevel'],
            'distance': distance,
            'radius': zone['radius'],
            'message': 'You are entering ${zone['name']} - Risk Level: ${zone['riskLevel']}',
          };
        }

        // Alert if approaching zone (within 500m buffer)
        if (distance <= zone['radius'] + 500) {
          return {
            'alert': true,
            'approaching': true,
            'zone': zone['name'],
            'distance': distance,
            'message': 'Approaching ${zone['name']} - Caution advised',
          };
        }
      }

      return null;
    } catch (e) {
      print('Geofence check error: $e');
      return null;
    }
  }

  // Detect anomalies in travel pattern
  static Future<Map<String, dynamic>?> detectAnomalies(
    List<Position> locationHistory,
  ) async {
    try {
      if (locationHistory.length < 3) return null;

      final lastPosition = locationHistory.last;
      final previousPosition = locationHistory[locationHistory.length - 2];

      // Calculate speed (km/h)
      double distance = _calculateDistance(
        previousPosition.latitude,
        previousPosition.longitude,
        lastPosition.latitude,
        lastPosition.longitude,
      );

      // Assuming 5 minute intervals between location updates
      double speed = (distance / 1000) / (5 / 60);

      // Alert if speed exceeds 100 km/h (suspicious travel)
      if (speed > 100) {
        return {
          'anomaly': true,
          'type': 'sudden_movement',
          'speed': speed.toStringAsFixed(2),
          'message': 'Unusual speed detected: ${speed.toStringAsFixed(2)} km/h',
        };
      }

      // Check for sudden location changes
      final positions = locationHistory.sublist(
        locationHistory.length - 5,
        locationHistory.length,
      );

      double maxDistance = 0;
      for (int i = 0; i < positions.length - 1; i++) {
        double dist = _calculateDistance(
          positions[i].latitude,
          positions[i].longitude,
          positions[i + 1].latitude,
          positions[i + 1].longitude,
        );
        if (dist > maxDistance) maxDistance = dist;
      }

      // Alert if jumped more than 1km in 5 minutes
      if (maxDistance > 1000) {
        return {
          'anomaly': true,
          'type': 'deviation_from_route',
          'distance': (maxDistance / 1000).toStringAsFixed(2),
          'message': 'Significant route deviation detected',
        };
      }

      return null;
    } catch (e) {
      print('Anomaly detection error: $e');
      return null;
    }
  }

  // Monitor location continuously
  static Future<void> startLocationMonitoring() async {
    try {
      final box = Hive.box(boxName);
      final locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100, // 100m minimum
        ),
      );

      locationStream.listen((Position position) async {
        // Store location
        List<dynamic> history = box.get('locationHistory', defaultValue: []);
        history.add({
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Keep only last 100 positions
        if (history.length > 100) {
          history = history.sublist(history.length - 100);
        }
        await box.put('locationHistory', history);

        // Check for geofence violations
        final geofenceAlert = await checkGeofence(
          position.latitude,
          position.longitude,
        );

        if (geofenceAlert != null) {
          _notifyAlertListeners(geofenceAlert);
        }

        // Detect anomalies
        final anomaly = await detectAnomalies(
          history
              .map((h) => Position(
                    latitude: h['lat'],
                    longitude: h['lng'],
                    timestamp: DateTime.parse(h['timestamp']),
                    accuracy: 0,
                    altitude: 0,
                    heading: 0,
                    speed: 0,
                    speedAccuracy: 0,
                  ))
              .toList(),
        );

        if (anomaly != null) {
          _notifyAlertListeners(anomaly);
        }
      });
    } catch (e) {
      print('Location monitoring error: $e');
    }
  }

  // Listen for geofence and anomaly alerts
  static void onAlert(Function(Map) callback) {
    _alertListeners.add(callback);
  }

  static void _notifyAlertListeners(Map alert) {
    for (var listener in _alertListeners) {
      listener(alert);
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371000; // Earth radius in meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
        (Math.cos(_toRadians(lat1)) *
            Math.cos(_toRadians(lat2)) *
            Math.sin(dLon / 2) *
            Math.sin(dLon / 2));

    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

class Math {
  static double sin(double x) => _sin(x);
  static double cos(double x) => _cos(x);
  static double atan2(double y, double x) => _atan2(y, x);
  static double sqrt(double x) => _sqrt(x);

  static double _sin(double x) {
    // Simple sine approximation
    return (x - (x * x * x / 6) + (x * x * x * x * x / 120)).toDouble();
  }

  static double _cos(double x) {
    return (1 - (x * x / 2) + (x * x * x * x / 24)).toDouble();
  }

  static double _atan2(double y, double x) {
    return (y / x).isNaN ? 0 : (y / x);
  }

  static double _sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double res = x;
    for (int i = 0; i < 32; i++) {
      res = (res + x / res) / 2;
    }
    return res;
  }
}
