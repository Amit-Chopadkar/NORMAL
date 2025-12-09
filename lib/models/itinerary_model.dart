import 'package:latlong2/latlong.dart';
import 'safe_route_model.dart';

/// A single stop in an itinerary
class ItineraryStop {
  final String id;
  final String name;
  final LatLng location;
  final String category;
  final String? description;
  final DateTime? scheduledTime;
  
  // Route to this stop from previous stop
  SafeRoute? routeFromPrevious;

  ItineraryStop({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    this.description,
    this.scheduledTime,
    this.routeFromPrevious,
  });

  ItineraryStop copyWith({
    String? id,
    String? name,
    LatLng? location,
    String? category,
    String? description,
    DateTime? scheduledTime,
    SafeRoute? routeFromPrevious,
  }) {
    return ItineraryStop(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      category: category ?? this.category,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      routeFromPrevious: routeFromPrevious ?? this.routeFromPrevious,
    );
  }
}

/// A complete day itinerary with multiple stops
class DayItinerary {
  final String id;
  final String title;
  final DateTime date;
  final List<ItineraryStop> stops;
  final LatLng? startLocation; // Hotel/current location

  DayItinerary({
    required this.id,
    required this.title,
    required this.date,
    required this.stops,
    this.startLocation,
  });

  /// Calculate overall safety score for the entire itinerary
  double get overallSafetyScore {
    if (stops.isEmpty) return 100.0;
    
    final routesWithScores = stops
        .where((stop) => stop.routeFromPrevious != null)
        .map((stop) => stop.routeFromPrevious!.safetyScore)
        .toList();

    if (routesWithScores.isEmpty) return 100.0;

    // Average safety score of all routes
    return routesWithScores.reduce((a, b) => a + b) / routesWithScores.length;
  }

  /// Get the lowest safety score among all routes
  double get lowestSafetyScore {
    if (stops.isEmpty) return 100.0;
    
    final scores = stops
        .where((stop) => stop.routeFromPrevious != null)
        .map((stop) => stop.routeFromPrevious!.safetyScore)
        .toList();

    if (scores.isEmpty) return 100.0;
    return scores.reduce((a, b) => a < b ? a : b);
  }

  /// Get total travel time in minutes
  double get totalTravelTime {
    return stops
        .where((stop) => stop.routeFromPrevious != null)
        .map((stop) => stop.routeFromPrevious!.estimatedDurationMin)
        .fold(0.0, (sum, duration) => sum + duration);
  }

  /// Get total distance in km
  double get totalDistance {
    return stops
        .where((stop) => stop.routeFromPrevious != null)
        .map((stop) => stop.routeFromPrevious!.distanceKm)
        .fold(0.0, (sum, distance) => sum + distance);
  }

  /// Get count of dangerous routes (safety < 60)
  int get dangerousRouteCount {
    return stops
        .where((stop) => 
            stop.routeFromPrevious != null && 
            stop.routeFromPrevious!.safetyScore < 60)
        .length;
  }

  /// Get all danger zones crossed in the entire itinerary
  List<DangerZoneCrossing> get allDangerZones {
    final zones = <DangerZoneCrossing>[];
    final seenZones = <String>{};

    for (final stop in stops) {
      if (stop.routeFromPrevious != null) {
        for (final zone in stop.routeFromPrevious!.dangerZonesCrossed) {
          if (!seenZones.contains(zone.name)) {
            zones.add(zone);
            seenZones.add(zone.name);
          }
        }
      }
    }

    return zones;
  }

  /// Get formatted total travel time
  String get formattedTotalTime {
    final totalMin = totalTravelTime;
    if (totalMin < 60) {
      return '${totalMin.round()} min';
    }
    final hours = (totalMin / 60).floor();
    final mins = (totalMin % 60).round();
    return '${hours}h ${mins}m';
  }

  /// Get formatted total distance
  String get formattedTotalDistance {
    if (totalDistance < 1) {
      return '${(totalDistance * 1000).round()} m';
    }
    return '${totalDistance.toStringAsFixed(1)} km';
  }

  /// Get safety status for the overall itinerary
  String get safetyStatus {
    final score = overallSafetyScore;
    if (score >= 75) return 'SAFE';
    if (score >= 50) return 'CAUTION';
    return 'RISKY';
  }

  /// Get color for overall safety
  String get safetyColor {
    final score = overallSafetyScore;
    if (score >= 75) return '#22c55e'; // Green
    if (score >= 50) return '#eab308'; // Yellow
    return '#ef4444'; // Red
  }

  /// Check if itinerary needs taxi recommendation
  bool get needsTaxiRecommendation {
    return dangerousRouteCount > 0 || lowestSafetyScore < 50;
  }

  DayItinerary copyWith({
    String? id,
    String? title,
    DateTime? date,
    List<ItineraryStop>? stops,
    LatLng? startLocation,
  }) {
    return DayItinerary(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      stops: stops ?? this.stops,
      startLocation: startLocation ?? this.startLocation,
    );
  }
}
