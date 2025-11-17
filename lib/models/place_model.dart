class Place {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String category;
  final String distance;
  final double rating;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.category,
    required this.distance,
    required this.rating,
    required this.latitude,
    required this.longitude,
  });
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