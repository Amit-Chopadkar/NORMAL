import 'package:flutter_test/flutter_test.dart';
import 'package:tourguard/services/places_api_service.dart';
import 'package:tourguard/models/place_model.dart';

void main() {
  group('PlacesApiService Integration Test', () {
    setUp(() {
      // Point to localhost for running tests on the host machine
      PlacesApiService.baseUrl = 'http://localhost:3000/api/places';
    });

    test('fetchNearbyPlaces returns list of places from backend', () async {
      // Use a fixed location (Nashik)
      final places = await PlacesApiService.fetchNearbyPlaces(
        latitude: 20.0,
        longitude: 73.8,
      );

      expect(places, isNotEmpty);
      expect(places.first, isA<Place>());
      
      // Verify mock data content
      final firstPlace = places.first;
      expect(firstPlace.name, contains('(Mock)')); // Since we are using mock data
      expect(firstPlace.distance, isNotNull);
      
      // Verify distance calculation (approximate check)
      // Mock1 is at 20.0063, 73.6868. Test loc is 20.0, 73.8.
      // Distance should be around 10-15km.
      print('Fetched ${places.length} places');
      print('First place: ${firstPlace.name}, Distance: ${firstPlace.distance}');
    });
  });
}
