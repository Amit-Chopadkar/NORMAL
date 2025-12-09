import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/place_model.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback? onAddToItinerary;

  const PlaceCard({super.key, required this.place, this.onAddToItinerary});

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'tourist_attraction':
      case 'famous':
        return Colors.purple;
      case 'restaurant':
      case 'food':
        return Colors.orange;
      case 'amusement_park':
      case 'adventure':
        return Colors.red;
      case 'park':
      case 'hidden-gem':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'tourist_attraction':
      case 'famous':
        return 'Famous Spot';
      case 'restaurant':
      case 'food':
        return 'Food & Dining';
      case 'amusement_park':
      case 'adventure':
        return 'Adventure';
      case 'park':
      case 'hidden-gem':
        return 'Hidden Gem';
      default:
        return 'Place';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(place.category);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: CachedNetworkImage(
              imageUrl: place.imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 120,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                height: 120,
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: categoryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _getCategoryLabel(place.category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  place.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 20, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (place.userRatingsTotal > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(${place.userRatingsTotal})',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      'Approx. ${place.distance} away',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          place.isOpen ? Icons.circle : Icons.circle_outlined,
                          size: 12,
                          color: place.isOpen ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.isOpen ? 'Open now' : 'Closed',
                          style: TextStyle(
                            fontSize: 13,
                            color: place.isOpen ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (onAddToItinerary != null)
                      OutlinedButton.icon(
                        onPressed: onAddToItinerary,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add to Trip'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          // Navigate to place details
                          _showPlaceDetails(context, place);
                        },
                        child: Text(
                          'View Details →',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceDetails(BuildContext context, Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                place.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                place.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              // Add more details here
            ],
          ),
        );
      },
    );
  }
}