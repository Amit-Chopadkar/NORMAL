import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'constants.dart';

class GeofenceHelper {
  /// Build a set of [Circle] objects from the predefined
  /// `AppConstants.geofenceZones` definition.
  static Set<Circle> buildFixedCircles() {
    return AppConstants.geofenceZones.map((z) {
      final color = Color((z['color'] as int));
      return Circle(
        circleId: CircleId(z['id'] as String),
        center: LatLng((z['latitude'] as double), (z['longitude'] as double)),
        radius: (z['radius'] as num).toDouble(),
        fillColor: color.withValues(alpha: 0.08),
        strokeColor: color.withValues(alpha: 0.6),
      );
    }).toSet();
  }
}
