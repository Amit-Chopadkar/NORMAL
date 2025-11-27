import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'api_environment.dart';
import 'backend_service.dart';

class ApiService {
  static String get baseUrl {
    // Always align with BackendService to avoid mismatched hosts
    // (this uses your PC's IP for physical devices, localhost for web)
    return BackendService.baseUrl;
  }
  static const String cacheBoxName = 'apiCache';

  static Future<void> initCache() async {
    await Hive.initFlutter();
    await Hive.openBox(cacheBoxName);
  }

  // Cache-aside pattern for GET requests
  static Future<dynamic> get(String endpoint) async {
    try {
      final box = Hive.box(cacheBoxName);
      final cacheKey = 'get_$endpoint';

      // Check cache first
      final cached = box.get(cacheKey);
      if (cached != null) {
        return cached;
      }

      // Fetch from API
      final response = await http.get(Uri.parse('$baseUrl$endpoint'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Cache the response
        await box.put(cacheKey, data);
        return data;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      // Return cached data on error
      final box = Hive.box(cacheBoxName);
      final cached = box.get('get_$endpoint');
      if (cached != null) {
        return cached;
      }
      throw Exception('Error: $e');
    }
  }

  // POST request
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body, {Duration? timeout}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(timeout ?? const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Clear specific cache
  static Future<void> clearCache(String endpoint) async {
    final box = Hive.box(cacheBoxName);
    await box.delete('get_$endpoint');
  }

  // Clear all cache
  static Future<void> clearAllCache() async {
    final box = Hive.box(cacheBoxName);
    await box.clear();
  }

  // Get nearby zones
  static Future<List<dynamic>> getNearbyZones(double lat, double lng) async {
    return await get('/zones?lat=$lat&lng=$lng');
  }

  // Get alerts
  static Future<List<dynamic>> getAlerts() async {
    return await get('/alerts');
  }

  // Get safety score
  static Future<Map<String, dynamic>> getSafetyScore() async {
    return await get('/safety-score');
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    return await get('/profile');
  }

  // Get places/explore data
  static Future<List<dynamic>> getPlaces() async {
    return await get('/places');
  }

  // Report incident
  static Future<Map<String, dynamic>> reportIncident(Map<String, dynamic> data) async {
    // Ensure user is authenticated if possible
    final token = await BackendService.getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    // Map app payload into backend DTO
    final location = data['location'] as Map<String, dynamic>?;
    final urgency = (data['urgency'] as String?) ?? 'Medium';

    String _mapSeverity(String u) {
      switch (u.toLowerCase()) {
        case 'critical':
          return 'CRITICAL';
        case 'high':
          return 'HIGH';
        case 'low':
          return 'LOW';
        case 'medium':
        default:
          return 'MEDIUM';
      }
    }

    // Store category and other metadata in description JSON
    final descriptionObj = {
      'originalMessage': data['description'],
      'category': data['category'] ?? 'Other',
      'status': 'reported',
    };

    final backendDto = {
      'title': data['title'],
      'description': jsonEncode(descriptionObj),
      'severity': _mapSeverity(urgency),
      // Store location as JSON string on backend
      'location': jsonEncode({
        'latitude': location?['latitude'],
        'longitude': location?['longitude'],
        'address': data['address'],
        if (data['userId'] != null) 'userId': data['userId'],
      }),
    };

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/incidents'),
            headers: headers,
            body: jsonEncode(backendDto),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to report incident: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Send SOS alert to emergency contacts (with shorter timeout for speed)
  static Future<Map<String, dynamic>> sendSOS({
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> emergencyContacts,
    String? userName,
  }) async {
    return await post('/sos/send', {
      'latitude': latitude,
      'longitude': longitude,
      'emergencyContacts': emergencyContacts,
      if (userName != null) 'userName': userName,
    }, timeout: const Duration(seconds: 3)); // Shorter timeout for faster response
  }
}
