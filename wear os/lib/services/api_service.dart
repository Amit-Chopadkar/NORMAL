import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sos_alert.dart';
import '../models/zone.dart';

class ApiService {
  // TODO: Configure this with your actual backend URL
  static String _baseUrl = 'http://10.0.2.2:5000'; // Default for Android emulator
  
  static void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get baseUrl => _baseUrl;

  // Send SOS Alert
  static Future<Map<String, dynamic>> sendSOSAlert(SOSAlert alert) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/sos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(alert.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Server returned ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Retry SOS Alert with exponential backoff
  static Future<Map<String, dynamic>> sendSOSAlertWithRetry(
    SOSAlert alert, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      final result = await sendSOSAlert(alert);
      if (result['success'] == true) {
        return result;
      }
      
      if (i < maxRetries - 1) {
        // Wait before retry: 2^i seconds
        await Future.delayed(Duration(seconds: 1 << i));
      }
    }
    
    return {
      'success': false,
      'error': 'Failed after $maxRetries attempts',
    };
  }

  // Fetch nearby zones
  static Future<List<Zone>> getNearbyZones(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/zones?lat=$lat&lng=$lng'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> zonesJson = data['data'] ?? data['zones'] ?? [];
        return zonesJson.map((json) => Zone.fromJson(json)).toList();
      } else {
        debugPrint('Failed to fetch zones: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching zones: $e');
      return [];
    }
  }

  // Check network connectivity
  static Future<bool> checkConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
