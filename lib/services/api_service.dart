import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
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
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

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
    return await post('/incidents/report', data);
  }
}
