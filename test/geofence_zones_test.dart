import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tourist_safety_hub/utils/constants.dart';

void main() {
  test('geofence zones map to fixed circle coordinates and radii', () {
    final zones = AppConstants.geofenceZones;
    expect(zones, isNotEmpty, reason: 'Expected predefined geofence zones to be present');

    for (final z in zones) {
      final id = z['id'] as String;
      final lat = (z['latitude'] as num).toDouble();
      final lng = (z['longitude'] as num).toDouble();
      final radius = (z['radius'] as num).toDouble();

      final circle = Circle(
        circleId: CircleId(id),
        center: LatLng(lat, lng),
        radius: radius,
      );

      expect(circle.circleId.value, equals(id));
      expect(circle.center.latitude, closeTo(lat, 1e-9));
      expect(circle.center.longitude, closeTo(lng, 1e-9));
      expect(circle.radius, equals(radius));
    }
  });
}
