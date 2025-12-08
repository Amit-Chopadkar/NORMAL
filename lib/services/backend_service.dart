import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to connect Flutter app to the new TourGuard backend API
class BackendService {
  // Base URL configuration
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // For Android physical device or emulator on same network
    return 'http://10.191.242.74:3000/api'; // Your PC's IP
    // If using emulator on same machine, use: http://10.0.2.2:3000/api
  }

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';

  /// Get stored authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Save authentication token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Get stored user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Save user ID
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  /// Clear stored credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        // Save token and user ID
        await saveToken(data['data']['token']);
        await saveUserId(data['data']['id']);
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  /// Login user
  static Future<Map<String, dynamic>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      if (email == null && phone == null) {
        throw Exception('Email or phone is required');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        // Save token and user ID
        await saveToken(data['data']['token']);
        await saveUserId(data['data']['id']);
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  /// Update user location
  static Future<void> updateLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/update-location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to update location');
      }
    } catch (e) {
      throw Exception('Location update error: $e');
    }
  }

  /// Log user activity
  static Future<void> logActivity({
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/activity'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': action,
          'metadata': metadata ?? {},
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to log activity');
      }
    } catch (e) {
      // Don't throw error for activity logging failures
      debugPrint('Activity logging error: $e');
    }
  }

  /// Create an alert (panic, SOS, danger zone entry)
  static Future<Map<String, dynamic>> createAlert({
    required String alertType, // 'panic', 'sos', 'danger_zone_entry'
    required double lat,
    required double lng,
    String? message,
  }) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/user/alert'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'alertType': alertType,
          'lat': lat,
          'lng': lng,
          'message': message ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return data['data']['alert'];
      } else {
        throw Exception(data['message'] ?? 'Failed to create alert');
      }
    } catch (e) {
      throw Exception('Alert creation error: $e');
    }
  }

  /// Send OTP to user's phone
  static Future<Map<String, dynamic>> sendOtp({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      throw Exception('Send OTP error: $e');
    }
  }

  /// Verify OTP and get hash ID
  static Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        // Save token and user ID (may be updated)
        await saveToken(data['data']['token']);
        await saveUserId(data['data']['id']);
        return data['data'];
      } else {
        throw Exception(data['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      throw Exception('OTP verification error: $e');
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Upload profile photo
  static Future<String> uploadProfilePhoto({required String filePath}) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/upload-photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('photo', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (data['success'] == true && data['data'] != null) {
        return data['data']['photoUrl'];
      } else {
        throw Exception(data['message'] ?? 'Failed to upload photo');
      }
    } catch (e) {
      throw Exception('Photo upload error: $e');
    }
  }
}
