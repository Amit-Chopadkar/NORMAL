import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:geolocator/geolocator.dart';

class IncidentService {
  static const String boxName = 'incidentBox';

  static Future<void> initIncidents() async {
    await Hive.openBox(boxName);
  }

  // Report incident with geo-tagging
  static Future<String> reportIncident({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    List<String>? attachments,
  }) async {
    try {
      final box = Hive.box(boxName);
      final incidentId = 'INC-${DateTime.now().millisecondsSinceEpoch}';

      final incident = {
        'id': incidentId,
        'title': title,
        'description': description,
        'category': category,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
          'address': 'Latitude: $latitude, Longitude: $longitude',
        },
        'attachments': attachments ?? [],
        'status': 'reported',
        'reportedAt': DateTime.now().toIso8601String(),
        'riskLevel': _calculateRiskLevel(category),
      };

      await box.put(incidentId, incident);

      // In real app, would send to server/authority
      print('Incident reported: $incidentId');

      return incidentId;
    } catch (e) {
      print('Error reporting incident: $e');
      return '';
    }
  }

  // Get all incidents
  static Future<List<Map<String, dynamic>>> getAllIncidents() async {
    try {
      final box = Hive.box(boxName);
      List<Map<String, dynamic>> incidents = [];

      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is Map) {
          incidents.add(Map<String, dynamic>.from(raw));
        }
      }

      return incidents;
    } catch (e) {
      print('Error getting incidents: $e');
      return [];
    }
  }

  // Get incident by ID
  static Future<Map<String, dynamic>?> getIncident(String incidentId) async {
    try {
      final box = Hive.box(boxName);
      return box.get(incidentId);
    } catch (e) {
      print('Error getting incident: $e');
      return null;
    }
  }

  // Update incident status
  static Future<bool> updateIncidentStatus(
    String incidentId,
    String newStatus,
  ) async {
    try {
      final box = Hive.box(boxName);
      Map<String, dynamic> incident = box.get(incidentId) ?? {};

      incident['status'] = newStatus;
      incident['updatedAt'] = DateTime.now().toIso8601String();

      await box.put(incidentId, incident);
      return true;
    } catch (e) {
      print('Error updating incident: $e');
      return false;
    }
  }

  // Generate E-FIR for missing person (automated)
  static Future<String> generateEFIR({
    required String personName,
    required String lastKnownLocation,
    required String description,
    required double latitude,
    required double longitude,
    String? photoUrl,
  }) async {
    try {
      final box = Hive.box(boxName);
      final efirId = 'EFIR-${DateTime.now().millisecondsSinceEpoch}';

      final efir = {
        'id': efirId,
        'type': 'missing_person',
        'personName': personName,
        'lastKnownLocation': lastKnownLocation,
        'description': description,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'photoUrl': photoUrl,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'active',
        'riskLevel': 'high',
      };

      await box.put(efirId, efir);

      print('E-FIR Generated: $efirId');
      return efirId;
    } catch (e) {
      print('Error generating E-FIR: $e');
      return '';
    }
  }

  // Real-time incident response
  static Future<bool> requestEmergencyResponse({
    required String incidentId,
    required String urgencyLevel,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final box = Hive.box(boxName);
      Map<String, dynamic> incident = box.get(incidentId) ?? {};

      incident['emergencyResponse'] = {
        'status': 'requested',
        'urgencyLevel': urgencyLevel,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'requestedAt': DateTime.now().toIso8601String(),
      };

      incident['status'] = 'emergency_response_requested';
      await box.put(incidentId, incident);

      // In real app, would notify police/authorities
      print('Emergency response requested for: $incidentId');
      return true;
    } catch (e) {
      print('Error requesting emergency response: $e');
      return false;
    }
  }

  // Get nearby incidents (heatmap data)
  static Future<List<Map<String, dynamic>>> getNearbyIncidents(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      final box = Hive.box(boxName);
      List<Map<String, dynamic>> nearby = [];

      for (var key in box.keys) {
        final raw = box.get(key);
        if (raw is! Map) continue;
        Map<String, dynamic> incident = Map<String, dynamic>.from(raw);
        double distance = _calculateDistance(
          latitude,
          longitude,
          incident['location']['latitude'],
          incident['location']['longitude'],
        );

        // _calculateDistance returns kilometers. Compare against radiusKm (km).
        if (kDebugMode) {
          debugPrint('[IncidentService] Distance to ${incident['id'] ?? 'unknown'}: ${distance.toStringAsFixed(3)} km (radius ${radiusKm} km)');
        }
        if (distance <= radiusKm) {
          nearby.add(incident);
        }
      }

      return nearby;
    } catch (e) {
      print('Error getting nearby incidents: $e');
      return [];
    }
  }

  // Helper functions
  static String _calculateRiskLevel(String category) {
    switch (category.toLowerCase()) {
      case 'theft':
      case 'assault':
      case 'missing_person':
        return 'high';
      case 'accident':
      case 'medical':
        return 'medium';
      default:
        return 'low';
    }
  }

  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  static double sin(double x) {
    return (x - (x * x * x / 6) + (x * x * x * x * x / 120)).toDouble();
  }

  static double cos(double x) {
    return (1 - (x * x / 2) + (x * x * x * x / 24)).toDouble();
  }

  static double atan2(double y, double x) {
    return (y / x).isNaN ? 0 : (y / x);
  }

  static double sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double res = x;
    for (int i = 0; i < 32; i++) {
      res = (res + x / res) / 2;
    }
    return res;
  }
}
