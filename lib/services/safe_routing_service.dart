import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../models/safe_route_model.dart';

/// Service for calculating safety-aware routes
class SafeRoutingService {
  // ML Engine endpoint
  static const String mlEngineBaseUrl = 'http://172.17.5.58:8082';
  
  /// Calculate safe route from origin to destination
  /// 
  /// Returns a list of route options with safety scores.
  /// The first route in the list is the recommended (safest) route.
  static Future<SafeRouteResponse> calculateSafeRoute({
    required LatLng origin,
    required LatLng destination,
    String touristId = 'flutter_user',
    String tripId = 'current_trip',
    RoutePreferences? preferences,
  }) async {
    try {
      final url = Uri.parse('$mlEngineBaseUrl/routes/safe-route');
      
      final requestBody = {
        'origin': {
          'lat': origin.latitude,
          'lng': origin.longitude,
        },
        'destination': {
          'lat': destination.latitude,
          'lng': destination.longitude,
        },
        'tourist_id': touristId,
        'trip_id': tripId,
        'preferences': (preferences ?? RoutePreferences()).toJson(),
      };

      if (kDebugMode) {
        print('[SafeRoutingService] Requesting safe route: ${jsonEncode(requestBody)}');
      }

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Route calculation timed out');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (kDebugMode) {
          print('[SafeRoutingService] Received ${jsonResponse['routes'].length} route(s)');
        }

        return SafeRouteResponse.fromJson(jsonResponse);
      } else {
        if (kDebugMode) {
          print('[SafeRoutingService] Error: ${response.statusCode} - ${response.body}');
        }
        throw Exception('Failed to calculate route: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SafeRoutingService] Exception: $e');
      }
      rethrow;
    }
  }

  /// Get safety score for a specific route
  /// 
  /// This is useful for validating custom routes or checking
  /// an existing route's safety status
  static Future<double> getSafetyScore({
    required List<LatLng> routePoints,
    DateTime? timeOfTravel,
  }) async {
    if (routePoints.length < 2) {
      throw ArgumentError('Route must have at least 2 points');
    }

    try {
      // Use the first and last points as origin/destination
      final result = await calculateSafeRoute(
        origin: routePoints.first,
        destination: routePoints.last,
        preferences: RoutePreferences(timeOfTravel: timeOfTravel),
      );

      return result.recommendedRoute.safetyScore;
    } catch (e) {
      if (kDebugMode) {
        print('[SafeRoutingService] Failed to get safety score: $e');
      }
      // Return a neutral score on error
      return 50.0;
    }
  }

  /// Check if a route crosses any danger zones
  static Future<List<DangerZoneCrossing>> getDangerZoneCrossings({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final result = await calculateSafeRoute(
        origin: origin,
        destination: destination,
      );

      return result.recommendedRoute.dangerZonesCrossed;
    } catch (e) {
      if (kDebugMode) {
        print('[SafeRoutingService] Failed to get danger zones: $e');
      }
      return [];
    }
  }

  /// Get the safest route from multiple alternatives
  /// 
  /// Helper method that sorts routes by safety score and returns the safest one
  static SafeRoute getSafestRoute(List<SafeRoute> routes) {
    if (routes.isEmpty) {
      throw ArgumentError('Routes list cannot be empty');
    }

    // Sort by safety score (descending) and return the first
    final sorted = List<SafeRoute>.from(routes)
      ..sort((a, b) => b.safetyScore.compareTo(a.safetyScore));

    return sorted.first;
  }

  /// Compare two routes and return the safer one
  static SafeRoute compareSafety(SafeRoute route1, SafeRoute route2) {
    // Primary: Compare safety scores
    if (route1.safetyScore != route2.safetyScore) {
      return route1.safetyScore > route2.safetyScore ? route1 : route2;
    }

    // Secondary: Prefer route with fewer high-risk zones
    if (route1.highRiskZones != route2.highRiskZones) {
      return route1.highRiskZones < route2.highRiskZones ? route1 : route2;
    }

    // Tertiary: Prefer shorter route if safety is equal
    return route1.distanceKm < route2.distanceKm ? route1 : route2;
  }
}
