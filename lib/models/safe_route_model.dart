import 'package:latlong2/latlong.dart';

/// Represents a danger zone that a route crosses
class DangerZoneCrossing {
  final String name;
  final String riskLevel; // 'low', 'medium', 'high'
  final String? advisory;

  DangerZoneCrossing({
    required this.name,
    required this.riskLevel,
    this.advisory,
  });

  factory DangerZoneCrossing.fromJson(Map<String, dynamic> json) {
    return DangerZoneCrossing(
      name: json['name'] as String,
      riskLevel: json['risk_level'] as String,
      advisory: json['advisory'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'risk_level': riskLevel,
      'advisory': advisory,
    };
  }
}

/// A route option with safety metadata
class SafeRoute {
  final List<LatLng> coordinates;
  final double safetyScore; // 0-100
  final List<DangerZoneCrossing> dangerZonesCrossed;
  final double estimatedDurationMin;
  final double distanceKm;
  final int highRiskZones;
  final int mediumRiskZones;
  final int lowRiskZones;

  SafeRoute({
    required this.coordinates,
    required this.safetyScore,
    required this.dangerZonesCrossed,
    required this.estimatedDurationMin,
    required this.distanceKm,
    required this.highRiskZones,
    required this.mediumRiskZones,
    required this.lowRiskZones,
  });

  factory SafeRoute.fromJson(Map<String, dynamic> json) {
    // Parse coordinates
    final coordsList = json['coordinates'] as List;
    final coords = coordsList.map((coord) {
      final lat = coord['lat'] as num;
      final lng = coord['lng'] as num;
      return LatLng(lat.toDouble(), lng.toDouble());
    }).toList();

    // Parse danger zones
    final zonesList = json['danger_zones_crossed'] as List;
    final zones = zonesList
        .map((zone) => DangerZoneCrossing.fromJson(zone as Map<String, dynamic>))
        .toList();

    return SafeRoute(
      coordinates: coords,
      safetyScore: (json['safety_score'] as num).toDouble(),
      dangerZonesCrossed: zones,
      estimatedDurationMin: (json['estimated_duration_min'] as num).toDouble(),
      distanceKm: (json['distance_km'] as num).toDouble(),
      highRiskZones: json['high_risk_zones'] as int? ?? 0,
      mediumRiskZones: json['medium_risk_zones'] as int? ?? 0,
      lowRiskZones: json['low_risk_zones'] as int? ?? 0,
    );
  }

  /// Get a color based on safety score
  String get safetyColor {
    if (safetyScore >= 75) return '#22c55e'; // Green
    if (safetyScore >= 50) return '#eab308'; // Yellow
    return '#ef4444'; // Red
  }

  /// Get safety status text
  String get safetyStatus {
    if (safetyScore >= 75) return 'SAFE';
    if (safetyScore >= 50) return 'CAUTION';
    return 'DANGER';
  }

  /// Get formatted duration string
  String get formattedDuration {
    if (estimatedDurationMin < 60) {
      return '${estimatedDurationMin.round()} min';
    }
    final hours = (estimatedDurationMin / 60).floor();
    final mins = (estimatedDurationMin % 60).round();
    return '${hours}h ${mins}m';
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Get total danger zones count
  int get totalDangerZones => highRiskZones + mediumRiskZones + lowRiskZones;

  /// Check if route is safe (no high-risk zones)
  bool get isSafe => highRiskZones == 0;
}

/// Response from safe route calculation
class SafeRouteResponse {
  final List<SafeRoute> routes;
  final int recommendedRouteIndex;
  final DateTime calculationTimestamp;

  SafeRouteResponse({
    required this.routes,
    required this.recommendedRouteIndex,
    required this.calculationTimestamp,
  });

  factory SafeRouteResponse.fromJson(Map<String, dynamic> json) {
    final routesList = json['routes'] as List;
    final routes = routesList
        .map((route) => SafeRoute.fromJson(route as Map<String, dynamic>))
        .toList();

    return SafeRouteResponse(
      routes: routes,
      recommendedRouteIndex: json['recommended_route_index'] as int,
      calculationTimestamp: DateTime.parse(json['calculation_timestamp'] as String),
    );
  }

  /// Get the recommended route
  SafeRoute get recommendedRoute => routes[recommendedRouteIndex];
}

/// Preferences for route calculation
class RoutePreferences {
  final bool avoidDangerZones;
  final double maxDetourPct; // 0-100
  final DateTime? timeOfTravel;

  RoutePreferences({
    this.avoidDangerZones = true,
    this.maxDetourPct = 30.0,
    this.timeOfTravel,
  });

  Map<String, dynamic> toJson() {
    return {
      'avoid_danger_zones': avoidDangerZones,
      'max_detour_pct': maxDetourPct,
      if (timeOfTravel != null) 'time_of_travel': timeOfTravel!.toIso8601String(),
    };
  }
}
