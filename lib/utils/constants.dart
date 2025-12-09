import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Tourist Safety Hub';
  static const String appVersion = '1.0.0';
  
  // API Endpoints (for future use)
  static const String baseUrl = 'https://api.touristsafetyhub.com';
  static const String alertsEndpoint = '$baseUrl/alerts';
  static const String locationsEndpoint = '$baseUrl/locations';
  
  // Default Values
  static const double defaultSafetyScore = 87.0;
  static const String defaultLocation = 'Nashik, Maharashtra';
  
  // Colors
  static const Color primaryColor = Color(0xFF1a2a6c);
  static const Color secondaryColor = Color(0xFF2c3e50);
  static const Color accentColor = Colors.orange;
  static const Color safeColor = Color(0xFF22c55e);
  static const Color cautionColor = Color(0xFFeab308);
  static const Color dangerColor = Color(0xFFef4444);
  
  // Icons
  static const IconData locationIcon = Icons.location_on;
  static const IconData safetyIcon = Icons.security;
  static const IconData alertIcon = Icons.warning;
  static const IconData emergencyIcon = Icons.emergency;
  static const IconData profileIcon = Icons.person;
  static const IconData settingsIcon = Icons.settings;
  static const IconData exploreIcon = Icons.explore;

  // Expose the demo geofence zones from DemoData for backward compatibility
  static List<Map<String, dynamic>> get geofenceZones => DemoData.geofenceZones;
}

class DemoData {
  static final List<Map<String, dynamic>> demoAlerts = [
    {
      'id': '1',
      'type': 'warning',
      'title': 'Zone Alert',
      'message': 'Approaching caution zone - Market Area',
      'location': 'Guwahati Market',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'isActive': true,
    },
    {
      'id': '2',
      'type': 'danger',
      'title': 'Security Alert',
      'message': 'Avoid remote forest area - increased risk level',
      'location': 'Forest Reserve',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'isActive': true,
    },
    {
      'id': '3',
      'type': 'info',
      'title': 'Weather Update',
      'message': 'Heavy rainfall expected in 1 hour',
      'location': 'Guwahati Market',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
      'isActive': true,
    },
  ];

  static final List<Map<String, dynamic>> demoPlaces = [
    {
      'id': '1',
      'name': 'Sula Vineyards',
      'description': 'India\'s most popular winery, perfect for tours and tasting.',
      'imageUrl': 'https://picsum.photos/seed/sula/400/200',
      'category': 'famous',
      'distance': '8 km',
      'rating': 4.5,
      'latitude': 20.0112,
      'longitude': 73.7909,
    },
    {
      'id': '2',
      'name': 'Sadhana Restaurant',
      'description': 'Experience authentic and delicious Chulivarchi Misal Pav.',
      'imageUrl': 'https://picsum.photos/seed/misal/400/200',
      'category': 'food',
      'distance': '5 km',
      'rating': 4.3,
      'latitude': 20.0112,
      'longitude': 73.7909,
    },
  ];

  // Predefined geofence zones with fixed coordinates (latitude, longitude) and radius in meters.
  // These are constant zones and do not move with the user's location.
  static final List<Map<String, dynamic>> geofenceZones = [
    {
      'id': 'RED_ZONE_1',
      'name': 'Danger zone ',
      'latitude': 25.611683,
      'longitude': 91.901651,
      'radius': 200,
      'color': 0xFFFF0000,
    },
        {
      'id': 'YELLOW_ZONE_2',
      'name': 'Forest zone ',
      'latitude': 25.612388,
      'longitude': 91.893788,
      'radius': 200,
      'color': 0xFFFFFF00,
    },
  ];
}