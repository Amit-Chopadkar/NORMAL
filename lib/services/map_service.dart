import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapService {
  static const List<Map<String, dynamic>> _safetyZones = [
    {
      'name': 'Tourist Zone',
      'type': 'safe',
      'distance': '0.2 km',
      'coordinates': LatLng(20.0112, 73.7909),
      'radius': 500.0,
    },
    {
      'name': 'Market Area',
      'type': 'caution',
      'distance': '0.5 km',
      'coordinates': LatLng(20.0098, 73.7954),
      'radius': 300.0,
    },
    {
      'name': 'Remote Forest',
      'type': 'danger',
      'distance': '2.1 km',
      'coordinates': LatLng(20.0050, 73.7850),
      'radius': 1000.0,
    },
  ];

  static List<Map<String, dynamic>> getSafetyZones() {
    return _safetyZones;
  }

  static String getZoneColor(String type) {
    switch (type) {
      case 'safe':
        return '#22c55e'; // green
      case 'caution':
        return '#eab308'; // yellow
      case 'danger':
        return '#ef4444'; // red
      default:
        return '#6b7280'; // gray
    }
  }

  static Map<String, dynamic>? getCurrentZone(LatLng currentLocation) {
    for (final zone in _safetyZones) {
      final zoneLocation = zone['coordinates'] as LatLng;
      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        zoneLocation.latitude,
        zoneLocation.longitude,
      );

      if (distance <= (zone['radius'] as double)) {
        return zone;
      }
    }
    return null;
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
      math.cos((lat2 - lat1) * p) / 2 +
      math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // meters
  }
}