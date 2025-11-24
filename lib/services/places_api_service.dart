import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';
import 'api_environment.dart';

class PlacesApiService {
  static String? _overrideBaseUrl;

  // Allows integration tests to override the base URL.
  static set baseUrl(String value) => _overrideBaseUrl = value;
  static void resetBaseUrlOverride() => _overrideBaseUrl = null;

  // The base URL now resolves dynamically based on platform and can be
  // overridden via --dart-define=PLACES_API_BASE_URL.
  static String get _baseUrl =>
      _overrideBaseUrl ?? ApiEnvironment.placesBaseUrl;
  static String get _googleApiKey => ApiEnvironment.googlePlacesApiKey;
  static bool get _canFallbackToGoogle => _googleApiKey.isNotEmpty;
  static const _requestTimeout = Duration(seconds: 10);

  static Future<List<Place>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 50000, // 50 km radius
    String type = 'all',
  }) async {
    final queryParams = <String, String>{
      'lat': latitude.toString(),
      'lng': longitude.toString(),
      'radius': radius.toString(),
    };

    if (type.isNotEmpty && type != 'all') {
      queryParams['type'] = type;
    }

    final uri = Uri.parse('$_baseUrl/nearby').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await http.get(uri).timeout(_requestTimeout);

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
          throw Exception(data['message'] ?? 'No places returned from API');
        }
      } else {
        throw Exception(
          'Failed to load places: HTTP ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      // ignore: avoid_print
      print('Places API timeout: $e');
      if (_canFallbackToGoogle) {
        return _fetchDirectlyFromGoogle(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          type: type,
        );
      }
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching places: $e');
      if (_canFallbackToGoogle) {
        return _fetchDirectlyFromGoogle(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          type: type,
        );
      }
      rethrow;
    }
  }

  static Future<List<Place>> _fetchDirectlyFromGoogle({
    required double latitude,
    required double longitude,
    required int radius,
    required String type,
  }) async {
    final Map<String, dynamic> body = {
      'locationRestriction': {
        'circle': {
          'center': {'latitude': latitude, 'longitude': longitude},
          'radius': radius,
        }
      },
    };
    if (type.isNotEmpty && type != 'all') {
      body['includedTypes'] = [type];
    }

    final response = await http
        .post(
          Uri.parse('https://places.googleapis.com/v1/places:searchNearby'),
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _googleApiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount,places.photos,places.types,places.regularOpeningHours',
          },
          body: jsonEncode(body),
        )
        .timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Google Places request failed with status ${response.statusCode}',
      );
    }

    final data = json.decode(response.body);
    final List<dynamic> places = data['places'] ?? [];

    return places.map<Place>((placeJson) {
      final normalized = _normalizeGooglePlace(placeJson);
      final place = Place.fromJson(normalized);
      final distanceInMeters = Geolocator.distanceBetween(
        latitude,
        longitude,
        place.latitude,
        place.longitude,
      );
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
  }

  static Map<String, dynamic> _normalizeGooglePlace(
    Map<String, dynamic> place,
  ) {
    final photos = (place['photos'] as List<dynamic>?)
        ?.map((photo) => 'https://places.googleapis.com/v1/${photo['name']}/'
            'media?maxHeightPx=400&maxWidthPx=400&key=$_googleApiKey')
        .toList();

    return {
      'place_id': place['id'],
      'name': place['displayName']?['text'],
      'vicinity': place['formattedAddress'],
      'types': place['types'],
      'geometry': {
        'location': {
          'lat': place['location']?['latitude'],
          'lng': place['location']?['longitude'],
        },
      },
      'photos': photos,
      'rating': place['rating'],
      'user_ratings_total': place['userRatingCount'],
      'opening_hours': {
        'open_now': place['regularOpeningHours']?['openNow'],
      },
    };
  }
}
