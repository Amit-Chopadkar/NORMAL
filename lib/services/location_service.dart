import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    // Check permissions
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } else {
      throw Exception('Location permission denied');
    }
  }

  static Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // In a real app, you would use Google Maps Geocoding API or similar
      // For demo, return a mock address
      return 'Nashik, Maharashtra, India';
    } catch (e) {
      return 'Unable to fetch address';
    }
  }

  static Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}