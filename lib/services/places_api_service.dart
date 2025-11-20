import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';

class PlacesApiService {
  // For Android emulator, use 10.0.2.2. For iOS simulator, use localhost.
  // For real device, use your machine's IP address.
  static String baseUrl = 'http://192.168.1.3:3000/api/places'; 

  static Future<List<Place>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String type = 'all',
  }) async {
    final uri = Uri.parse('$baseUrl/nearby').replace(queryParameters: {
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': radius.toString(),
      'type': type,
    });

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final List<dynamic> placesJson = data['data'];
          return placesJson.map((json) {
            final place = Place.fromJson(json);
            // Calculate distance
            final distanceInMeters = Geolocator.distanceBetween(
              latitude,
              longitude,
              place.latitude,
              place.longitude,
            );
            // Create a new Place with updated distance string
            return Place(
              id: place.id,
              name: place.name,
              description: place.description,
              imageUrl: place.imageUrl,
              category: place.category,
              distance: '${(distanceInMeters / 1000).toStringAsFixed(1)} km',
              rating: place.rating,
              userRatingsTotal: place.userRatingsTotal,
              latitude: place.latitude,
              longitude: place.longitude,
              isOpen: place.isOpen,
            );
          }).toList();
        } else {
          throw Exception('API returned error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load places: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching places: $e');
      // Return empty list or rethrow depending on desired behavior
      // For now rethrow to let UI handle error state
      rethrow;
    }
  }
}
