import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Position? _lastKnownPosition;

  // Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request location permissions
  static Future<bool> hasLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      // Check permissions
      if (!await hasLocationPermission()) {
        debugPrint('Location permission permanently denied');
        return _lastKnownPosition;
      }

      // Check if service is enabled
      if (!await isLocationServiceEnabled()) {
        debugPrint('Location service is disabled');
        return _lastKnownPosition;
      }

      // Get position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return _lastKnownPosition;
    }
  }

  // Get last known location (cached)
  static Position? getLastKnownLocation() {
    return _lastKnownPosition;
  }

  // Stream of location updates (for continuous monitoring)
  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    );
  }

  // Calculate distance between two points (in meters)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
