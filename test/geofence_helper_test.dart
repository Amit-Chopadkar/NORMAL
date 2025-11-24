import 'package:flutter_test/flutter_test.dart';
import 'package:tourguard/utils/constants.dart';
import 'package:tourguard/utils/geofence_helper.dart';

void main() {
  test('GeofenceHelper builds circles matching AppConstants', () {
    final zones = AppConstants.geofenceZones;
    final circles = GeofenceHelper.buildFixedCircles();

    expect(circles.length, equals(zones.length));

    for (final z in zones) {
      final id = z['id'] as String;
      final lat = (z['latitude'] as num).toDouble();
      final lng = (z['longitude'] as num).toDouble();
      final radius = (z['radius'] as num).toDouble();

      final circle = circles.firstWhere((c) => c.circleId.value == id);

      expect(circle.center.latitude, closeTo(lat, 1e-9));
      expect(circle.center.longitude, closeTo(lng, 1e-9));
      expect(circle.radius, equals(radius));
    }
  });
}
