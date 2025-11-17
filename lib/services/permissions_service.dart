import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionsService {
  // Request location permissions
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  // Request notification permissions (Android 13+)
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check if location service is enabled
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Request all permissions at once
  static Future<Map<String, bool>> requestAllPermissions() async {
    return {
      'location': await requestLocationPermission(),
      'notification': await requestNotificationPermission(),
    };
  }

  // Check current permission status
  static Future<PermissionStatus> getLocationStatus() async {
    return await Permission.location.status;
  }

  static Future<PermissionStatus> getNotificationStatus() async {
    return await Permission.notification.status;
  }
}
