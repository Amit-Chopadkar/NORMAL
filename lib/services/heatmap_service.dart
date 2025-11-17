import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeatmapService {
  // Generate heatmap circles for incident density visualization
  static Set<Circle> generateHeatmapCircles(List<Map<String, dynamic>> incidents) {
    final Set<Circle> circles = {};
    
    // Group incidents by proximity (cluster nearby incidents)
    final Map<String, List<Map<String, dynamic>>> clusters = {};
    
    for (var incident in incidents) {
      final lat = (incident['location']['latitude'] as num).toDouble();
      final lng = (incident['location']['longitude'] as num).toDouble();
      
      // Round to nearest 0.01 degree (approximately 1km grid)
      final key = '${(lat * 100).round()}|${(lng * 100).round()}';
      clusters.putIfAbsent(key, () => []).add(incident);
    }
    
    // Create circles for each cluster
    int circleId = 0;
    for (var entry in clusters.entries) {
      final parts = entry.key.split('|');
      final clusterLat = int.parse(parts[0]) / 100.0;
      final clusterLng = int.parse(parts[1]) / 100.0;
      final count = entry.value.length;
      
      // Color intensity based on incident count
      final color = _getHeatmapColor(count);
      final radius = _getRadiusForCount(count);
      
      circles.add(Circle(
        circleId: CircleId('heatmap_$circleId'),
        center: LatLng(clusterLat, clusterLng),
        radius: radius,
        fillColor: color,
        strokeColor: color.withOpacity(0.8),
        strokeWidth: 2,
      ));
      
      circleId++;
    }
    
    return circles;
  }
  
  // Get color based on incident intensity (green=safe, yellow=moderate, red=high)
  static Color _getHeatmapColor(int count) {
    if (count >= 10) return const Color(0x88FF0000); // Red (high)
    if (count >= 5) return const Color(0x88FFA500);  // Orange (moderate-high)
    if (count >= 3) return const Color(0x88FFFF00);  // Yellow (moderate)
    return const Color(0x88FFC0CB);                  // Pink (low)
  }
  
  // Get radius based on count (more incidents = larger circle)
  static double _getRadiusForCount(int count) {
    if (count >= 10) return 400.0;
    if (count >= 5) return 300.0;
    if (count >= 3) return 200.0;
    return 100.0;
  }
  
  // Calculate safety score for a location (0-100, higher = safer)
  static int calculateSafetyScore(double latitude, double longitude, List<Map<String, dynamic>> incidents) {
    // Find incidents within 2km
    const nearbyRadiusKm = 2.0;
    int nearbyCount = 0;
    
    for (var incident in incidents) {
      final incLat = (incident['location']['latitude'] as num).toDouble();
      final incLng = (incident['location']['longitude'] as num).toDouble();
      final distance = _calculateDistance(latitude, longitude, incLat, incLng);
      
      if (distance <= nearbyRadiusKm) {
        final weight = (incident['riskLevel'] == 'high') ? 2 : 1;
        nearbyCount += weight;
      }
    }
    
    // Calculate safety score: 100 (safest) to 0 (most incidents)
    return (100 - (nearbyCount * 5)).clamp(0, 100);
  }
  
  // Haversine formula to calculate distance between two points in km
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth's radius in km
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}
