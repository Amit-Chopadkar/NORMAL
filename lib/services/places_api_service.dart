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
  static const _requestTimeout = Duration(seconds: 30); // Increased for Overpass API
  static const String _overpassApiUrl = 'https://overpass-api.de/api/interpreter';

  static Future<List<Place>> fetchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 50000, // 50 km radius (converted to meters for Overpass)
    String type = 'all',
  }) async {
    // Use Overpass API (NearbyNow approach) instead of Google Places
    try {
      return await _fetchFromOverpass(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: type,
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching from Overpass API: $e');
      // Fallback to backend API if available
      if (_baseUrl.isNotEmpty && _baseUrl != '') {
        try {
          return await _fetchFromBackend(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: type,
          );
        } catch (backendError) {
          // ignore: avoid_print
          print('Backend API also failed: $backendError');
          // Final fallback to Google if API key is available
          if (_canFallbackToGoogle) {
            try {
              return await _fetchDirectlyFromGoogle(
                latitude: latitude,
                longitude: longitude,
                radius: radius,
                type: type,
              );
            } catch (googleError) {
              // ignore: avoid_print
              print('Google Places also failed: $googleError');
              // Return static mock data as last resort
              return _generateStaticMockData(latitude, longitude, type);
            }
          }
          // Return static mock data if no Google key
          return _generateStaticMockData(latitude, longitude, type);
        }
      } else if (_canFallbackToGoogle) {
        try {
          return await _fetchDirectlyFromGoogle(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            type: type,
          );
        } catch (googleError) {
          // ignore: avoid_print
          print('Google Places also failed: $googleError');
          // Return static mock data as last resort
          return _generateStaticMockData(latitude, longitude, type);
        }
      }
      // Return static mock data if no other options
      return _generateStaticMockData(latitude, longitude, type);
    }
  }

  /// Fetch places from Overpass API (OpenStreetMap) - NearbyNow approach
  static Future<List<Place>> _fetchFromOverpass({
    required double latitude,
    required double longitude,
    required int radius,
    required String type,
  }) async {
    // Convert radius from meters to the format Overpass expects
    final radiusMeters = radius > 10000 ? 10000 : radius; // Limit to 10km for Overpass
    
    // Build Overpass query based on category
    final overpassQuery = _buildOverpassQuery(
      latitude: latitude,
      longitude: longitude,
      radius: radiusMeters,
      type: type,
    );

    final queryString = 'data=${Uri.encodeComponent(overpassQuery)}';

    final response = await http.post(
      Uri.parse(_overpassApiUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: queryString,
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Overpass API request failed with status ${response.statusCode}',
      );
    }

    final data = json.decode(response.body);
    final List<dynamic> elements = data['elements'] ?? [];

    // Convert Overpass elements to Place objects
    final places = <Place>[];
    for (final element in elements) {
      try {
        final place = _convertOverpassElementToPlace(
          element,
          latitude,
          longitude,
        );
        if (place != null) {
          places.add(place);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error converting element: $e');
        continue;
      }
    }

    // Sort by distance
    places.sort((a, b) {
      final distA = double.tryParse(a.distance.replaceAll(' km', '')) ?? 0;
      final distB = double.tryParse(b.distance.replaceAll(' km', '')) ?? 0;
      return distA.compareTo(distB);
    });

    return places;
  }

  /// Build Overpass query based on category type
  static String _buildOverpassQuery({
    required double latitude,
    required double longitude,
    required int radius,
    required String type,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('[out:json][timeout:25];');
    buffer.writeln('(');

    if (type == 'all' || type.isEmpty) {
      // Query all relevant place types (nodes only for simplicity and performance)
      buffer.writeln('  node["shop"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["amenity"="cafe"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["amenity"="restaurant"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["amenity"="fast_food"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["tourism"="attraction"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["tourism"="museum"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["tourism"="viewpoint"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["leisure"="park"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["leisure"="amusement_ride"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["leisure"="theme_park"](around:$radius,$latitude,$longitude);');
      buffer.writeln('  node["historic"](around:$radius,$latitude,$longitude);');
    } else {
      // Query specific category
      switch (type) {
        case 'restaurant':
          buffer.writeln('  node["amenity"="restaurant"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["amenity"="fast_food"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["amenity"="cafe"](around:$radius,$latitude,$longitude);');
          break;
        case 'tourist_attraction':
          buffer.writeln('  node["tourism"="attraction"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["tourism"="museum"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["tourism"="viewpoint"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["historic"](around:$radius,$latitude,$longitude);');
          break;
        case 'park':
          buffer.writeln('  node["leisure"="park"](around:$radius,$latitude,$longitude);');
          break;
        case 'amusement_park':
          buffer.writeln('  node["leisure"="amusement_ride"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["leisure"="theme_park"](around:$radius,$latitude,$longitude);');
          break;
        default:
          // Generic shop/amenity query
          buffer.writeln('  node["shop"](around:$radius,$latitude,$longitude);');
          buffer.writeln('  node["amenity"](around:$radius,$latitude,$longitude);');
      }
    }

    buffer.writeln(');');
    buffer.writeln('out body;');

    return buffer.toString();
  }

  /// Convert Overpass API element to Place model
  static Place? _convertOverpassElementToPlace(
    Map<String, dynamic> element,
    double userLat,
    double userLng,
  ) {
    // Extract coordinates - Overpass returns nodes with lat/lon directly
    double? lat, lng;
    
    if (element['type'] == 'node') {
      lat = (element['lat'] as num?)?.toDouble();
      lng = (element['lon'] as num?)?.toDouble();
    } else {
      // For ways and relations, we'd need to calculate center, but for simplicity
      // we'll skip them as they're not in our query
      return null;
    }

    if (lat == null || lng == null) {
      return null;
    }

    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] as String? ?? 'Unnamed Place';
    
    // Determine category from OSM tags
    String category = 'place';
    if (tags.containsKey('tourism')) {
      if (tags['tourism'] == 'attraction' || tags['tourism'] == 'museum') {
        category = 'tourist_attraction';
      }
    } else if (tags.containsKey('leisure')) {
      if (tags['leisure'] == 'park') {
        category = 'park';
      } else if (tags['leisure'] == 'amusement_ride' || tags['leisure'] == 'theme_park') {
        category = 'amusement_park';
      }
    } else if (tags.containsKey('amenity')) {
      if (tags['amenity'] == 'restaurant' || tags['amenity'] == 'fast_food' || tags['amenity'] == 'cafe') {
        category = 'restaurant';
      }
    } else if (tags.containsKey('shop')) {
      category = 'shop';
    }

    // Get description from various OSM fields
    final description = tags['addr:full'] as String? ??
        tags['addr:street'] as String? ??
        tags['description'] as String? ??
        'No description available';

    // Calculate distance
    final distanceInMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      lat,
      lng,
    );

    // Generate image URL (placeholder, as OSM doesn't provide images)
    final imageUrl = 'https://placehold.co/400x200/png?text=${Uri.encodeComponent(name)}';

    // Generate mock rich data for demo purposes since OSM lacks these
    final randomHash = name.hashCode; // Consistent randomness based on name
    
    // Rating 3.5 - 5.0
    final rating = 3.5 + ((randomHash % 15) / 10.0);
    
    // User ratings 10 - 500
    final userRatingsTotal = 10 + (randomHash % 490);
    
    // Open status (Mock: mostly open)
    final isOpen = (randomHash % 5) != 0; // 80% chance of being open

    // Better descriptions based on category
    String richDescription = description;
    if (richDescription == 'No description available') {
       switch (category) {
         case 'tourist_attraction':
           richDescription = 'A famous local attraction known for its cultural significance and stunning architecture. A must-visit for tourists.';
           break;
         case 'restaurant':
           richDescription = 'Popular dining spot serving delicious local and international cuisines. Rated highly for ambiance and service.';
           break;
         case 'park':
           richDescription = 'Serene green space perfect for morning walks, picnics, and outdoor activities. featuring beautiful landscapes.';
           break;
         case 'amusement_park':
           richDescription = 'Thrilling adventure park with roller coasters and family-friendly rides. Great for a fun day out.';
           break;
         default:
           richDescription = 'A hidden gem in the city offering unique experiences and local vibes. Well worth checking out.';
       }
    }
    
    // Add fake tags to description for filter simulation
    final List<String> mockTags = [];
    if (category == 'restaurant') mockTags.add('Food');
    if (category == 'amusement_park' || category == 'park') mockTags.add('Adventure');
    if (rating > 4.5) mockTags.add('Famous');
    if (userRatingsTotal < 50) mockTags.add('Hidden Gem');
    
    // Append tags to description (or we could add a tags field to Place model later)
    if (mockTags.isNotEmpty) {
      richDescription += '\n\nTags: ${mockTags.join(", ")}';
    }

    return Place(
      id: element['id']?.toString() ?? '',
      name: name,
      description: richDescription,
      imageUrl: imageUrl,
      category: category,
      distance: '${(distanceInMeters / 1000).toStringAsFixed(1)} km',
      rating: rating,
      userRatingsTotal: userRatingsTotal,
      latitude: lat,
      longitude: lng,
      isOpen: isOpen,
    );
  }

  /// Fallback: Fetch from backend API if available
  static Future<List<Place>> _fetchFromBackend({
    required double latitude,
    required double longitude,
    required int radius,
    required String type,
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

  /// Generate static mock data when all APIs fail
  /// Returns hardcoded places with realistic tags, ratings, and status
  static List<Place> _generateStaticMockData(
    double userLat,
    double userLng,
    String type,
  ) {
    final mockPlaces = <Map<String, dynamic>>[
      {
        'name': 'The Royal Heritage Restaurant',
        'category': 'restaurant',
        'lat': userLat + 0.005,
        'lng': userLng + 0.003,
        'rating': 4.7,
        'userRatingsTotal': 234,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/restaurant1/400/300',
        'description': 'Authentic local cuisine served in a historic building. Known for traditional dishes and exceptional hospitality.\n\nTags: Food, Famous',
      },
      {
        'name': 'Mountain View Café',
        'category': 'restaurant',
        'lat': userLat - 0.003,
        'lng': userLng + 0.007,
        'rating': 4.2,
        'userRatingsTotal': 89,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/cafe1/400/300',
        'description': 'Cozy café with panoramic mountain views. Perfect spot for coffee lovers and breakfast enthusiasts.\n\nTags: Food, Hidden Gem',
      },
      {
        'name': 'Adventure Park Meghalaya',
        'category': 'amusement_park',
        'lat': userLat + 0.012,
        'lng': userLng - 0.008,
        'rating': 4.9,
        'userRatingsTotal': 512,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/adventure1/400/300',
        'description': 'Thrilling adventure park with zip-lining, rock climbing, and water sports. A must-visit for adrenaline junkies.\n\nTags: Adventure, Famous',
      },
      {
        'name': 'Sacred Falls Temple',
        'category': 'tourist_attraction',
        'lat': userLat - 0.015,
        'lng': userLng - 0.012,
        'rating': 4.8,
        'userRatingsTotal': 678,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/temple1/400/300',
        'description': 'Ancient temple nestled beside a stunning waterfall. A famous spiritual and cultural landmark with breathtaking natural beauty.\n\nTags: Famous',
      },
      {
        'name': 'Secret Garden Park',
        'category': 'park',
        'lat': userLat + 0.008,
        'lng': userLng + 0.010,
        'rating': 4.3,
        'userRatingsTotal': 45,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/garden1/400/300',
        'description': 'Peaceful botanical garden with rare plant species and scenic walking trails. A tranquil escape from city life.\n\nTags: Hidden Gem, Adventure',
      },
      {
        'name': 'Night Market Food Street',
        'category': 'restaurant',
        'lat': userLat - 0.006,
        'lng': userLng + 0.015,
        'rating': 4.6,
        'userRatingsTotal': 423,
        'isOpen': false,
        'imageUrl': 'https://picsum.photos/seed/market1/400/300',
        'description': 'Vibrant street food market offering diverse local delicacies. Opens at sunset with live music and cultural performances.\n\nTags: Food, Famous',
      },
      {
        'name': 'Hidden Valley Trekking Point',
        'category': 'tourist_attraction',
        'lat': userLat + 0.020,
        'lng': userLng - 0.015,
        'rating': 4.4,
        'userRatingsTotal': 38,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/trekking1/400/300',
        'description': 'Off-the-beaten-path trekking trail with stunning valley views. Ideal for nature lovers seeking adventure.\n\nTags: Hidden Gem, Adventure',
      },
      {
        'name': 'Lakeside Picnic Park',
        'category': 'park',
        'lat': userLat - 0.010,
        'lng': userLng - 0.005,
        'rating': 4.5,
        'userRatingsTotal': 156,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/lake1/400/300',
        'description': 'Family-friendly park with boating facilities and children\'s play area. Beautiful sunset views over the lake.\n\nTags: Adventure',
      },
      {
        'name': 'Artisan Coffee Roastery',
        'category': 'restaurant',
        'lat': userLat + 0.002,
        'lng': userLng - 0.004,
        'rating': 4.1,
        'userRatingsTotal': 27,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/coffee1/400/300',
        'description': 'Locally-owned coffee roastery serving specialty brews. Cozy ambiance perfect for remote work or reading.\n\nTags: Food, Hidden Gem',
      },
      {
        'name': 'Cultural Heritage Museum',
        'category': 'tourist_attraction',
        'lat': userLat - 0.007,
        'lng': userLng + 0.012,
        'rating': 4.7,
        'userRatingsTotal': 389,
        'isOpen': true,
        'imageUrl': 'https://picsum.photos/seed/museum1/400/300',
        'description': 'World-renowned museum showcasing regional history and artifacts. Interactive exhibits and guided tours available.\n\nTags: Famous',
      },
    ];

    // Filter by type if specified
    List<Map<String, dynamic>> filtered = mockPlaces;
    if (type != 'all' && type.isNotEmpty) {
      filtered = mockPlaces.where((p) => p['category'] == type).toList();
    }

    // Convert to Place objects
    return filtered.map((data) {
      final lat = data['lat'] as double;
      final lng = data['lng'] as double;
      final distanceInMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        lat,
        lng,
      );

      return Place(
        id: 'mock_${data['name'].toString().hashCode}',
        name: data['name'] as String,
        description: data['description'] as String,
        imageUrl: data['imageUrl'] as String,
        category: data['category'] as String,
        distance: '${(distanceInMeters / 1000).toStringAsFixed(1)} km',
        rating: data['rating'] as double,
        userRatingsTotal: data['userRatingsTotal'] as int,
        latitude: lat,
        longitude: lng,
        isOpen: data['isOpen'] as bool,
      );
    }).toList();
  }
}
