class Place {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String distance;
  final double rating;
  final int userRatingsTotal;
  final double latitude;
  final double longitude;
  final bool isOpen;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.distance,
    required this.rating,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    this.isOpen = false,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry']['location'];
    final photos = json['photos'] as List<dynamic>?;
    // Use a placeholder if no photo is available. 
    // In a real app, you'd construct the Google Places Photo URL here.
    final photoUrl = (photos != null && photos.isNotEmpty && !photos[0].toString().startsWith('mock_'))
        ? photos[0].toString()
        : 'https://placehold.co/400x200/png?text=${Uri.encodeComponent(json['name'] ?? 'Place')}'; 

    return Place(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Place',
      description: json['vicinity'] ?? '',
      imageUrl: photoUrl, // For now using placeholder logic or mock
      category: (json['types'] as List<dynamic>?)?.first.toString() ?? 'place',
      distance: '0 km', // Calculated later
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt() ?? 0,
      latitude: (geometry['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (geometry['lng'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['opening_hours']?['open_now'] ?? false,
    );
  }
}

class PlaceCategory {
  final String id;
  final String name;
  final bool isSelected;

  PlaceCategory({
    required this.id,
    required this.name,
    required this.isSelected,
  });

  PlaceCategory copyWith({bool? isSelected}) {
    return PlaceCategory(
      id: id,
      name: name,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}