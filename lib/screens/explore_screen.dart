import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../widgets/place_card.dart';
import '../widgets/filter_chip.dart';
import '../services/localization_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final List<PlaceCategory> _categories = [
    PlaceCategory(id: 'all', name: tr('all'), isSelected: true),
    PlaceCategory(id: 'famous', name: tr('famous'), isSelected: false),
    PlaceCategory(id: 'food', name: tr('food'), isSelected: false),
    PlaceCategory(id: 'adventure', name: tr('adventure'), isSelected: false),
    PlaceCategory(id: 'hidden-gem', name: tr('hidden_gems'), isSelected: false),
  ];

  final List<Place> _places = [
    Place(
      id: '1',
      name: 'Sula Vineyards',
      description: 'India\'s most popular winery, perfect for tours and tasting.',
      imageUrl: 'https://picsum.photos/seed/sula/400/200',
      category: 'famous',
      distance: '8 km',
      rating: 4.5,
      latitude: 20.0112,
      longitude: 73.7909,
    ),
    Place(
      id: '2',
      name: 'Sadhana Restaurant',
      description: 'Experience authentic and delicious Chulivarchi Misal Pav.',
      imageUrl: 'https://picsum.photos/seed/misal/400/200',
      category: 'food',
      distance: '5 km',
      rating: 4.3,
      latitude: 20.0112,
      longitude: 73.7909,
    ),
    Place(
      id: '3',
      name: 'Zonkers Adventure Park',
      description: 'Thrilling activities like go-karting, ziplining, and more.',
      imageUrl: 'https://picsum.photos/seed/adventure/400/200',
      category: 'adventure',
      distance: '9 km',
      rating: 4.2,
      latitude: 20.0112,
      longitude: 73.7909,
    ),
    Place(
      id: '4',
      name: 'Pandavleni Caves',
      description: 'A group of ancient rock-cut caves with stunning views.',
      imageUrl: 'https://picsum.photos/seed/caves/400/200',
      category: 'famous',
      distance: '6 km',
      rating: 4.4,
      latitude: 20.0112,
      longitude: 73.7909,
    ),
    Place(
      id: '5',
      name: 'Veda Mandir',
      description: 'A serene and architecturally beautiful temple, perfect for peace.',
      imageUrl: 'https://picsum.photos/seed/temple/400/200',
      category: 'hidden-gem',
      distance: '4 km',
      rating: 4.6,
      latitude: 20.0112,
      longitude: 73.7909,
    ),
  ];

  List<Place> get _filteredPlaces {
    final selectedCategory = _categories.firstWhere((cat) => cat.isSelected);
    if (selectedCategory.id == 'all') {
      return _places;
    }
    return _places.where((place) => place.category == selectedCategory.id).toList();
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      for (var category in _categories) {
        category = category.copyWith(isSelected: category.id == categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return _buildExplore();
      },
    );
  }

  Widget _buildExplore() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 24), // Top padding
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('explore_nashik'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.search, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChipWidget(
                        category: category,
                        onSelected: _onCategorySelected,
                      ),
                    );
                  },
                ),
              ),

              // Places List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredPlaces.length,
                  itemBuilder: (context, index) {
                    final place = _filteredPlaces[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlaceCard(place: place),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}