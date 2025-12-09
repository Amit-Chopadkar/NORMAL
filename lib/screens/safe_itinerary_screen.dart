import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/itinerary_model.dart';
import '../models/safe_route_model.dart';
import '../models/place_model.dart';
import '../services/itinerary_service.dart';
import '../services/location_service.dart';

/// Screen for creating and viewing safe itineraries
class SafeItineraryScreen extends StatefulWidget {
  const SafeItineraryScreen({Key? key}) : super(key: key);

  @override
  State<SafeItineraryScreen> createState() => _SafeItineraryScreenState();
}

class _SafeItineraryScreenState extends State<SafeItineraryScreen> {
  final _itineraryService = ItineraryService();
  bool _isCalculating = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initItinerary();
  }

  Future<void> _initItinerary() async {
    // Get current location for start point
    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });

      // Create itinerary if doesn't exist
      if (_itineraryService.currentItinerary == null) {
        _itineraryService.createItinerary(
          title: 'My Day Trip',
          date: DateTime.now(),
          startLocation: LatLng(position.latitude, position.longitude),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _calculateRoutes() async {
    setState(() {
      _isCalculating = true;
    });

    try {
      await _itineraryService.calculateRoutes();
      setState(() {
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Routes calculated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isCalculating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeStop(String stopId) {
    setState(() {
      _itineraryService.removeStop(stopId);
    });
  }

  Color _getSafetyColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final itinerary = _itineraryService.currentItinerary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Itinerary Planner'),
        backgroundColor: Colors.blue,
        actions: [
          if (itinerary != null && itinerary.stops.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _itineraryService.clearItinerary();
                setState(() {});
                Navigator.pop(context);
              },
              tooltip: 'Clear itinerary',
            ),
        ],
      ),
      body: itinerary == null || itinerary.stops.isEmpty
          ? _buildEmptyState()
          : _buildItineraryView(itinerary),
      floatingActionButton: itinerary != null && itinerary.stops.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isCalculating ? null : _calculateRoutes,
              icon: _isCalculating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.route),
              label: Text(_isCalculating ? 'Calculating...' : 'Calculate Routes'),
              backgroundColor: _isCalculating ? Colors.grey : Colors.blue,
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No places added yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Go back to Explore and add places to your itinerary',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.explore),
            label: const Text('Browse Places'),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryView(DayItinerary itinerary) {
    final hasRoutes = itinerary.stops.any((s) => s.routeFromPrevious != null);

    return Column(
      children: [
        // Summary Card
        if (hasRoutes) _buildSummaryCard(itinerary),
        
        // Stops List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: itinerary.stops.length,
            itemBuilder: (context, index) {
              final stop = itinerary.stops[index];
              final isFirst = index == 0;

              return Column(
                children: [
                  // Route segment (if not first)
                  if (!isFirst && stop.routeFromPrevious != null)
                    _buildRouteSegment(stop.routeFromPrevious!),
                  
                  // Stop card
                  _buildStopCard(stop, index + 1),
                  
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),

        // Recommendations
        if (hasRoutes) _buildRecommendations(itinerary),
      ],
    );
  }

  Widget _buildSummaryCard(DayItinerary itinerary) {
    final safetyColor = _getSafetyColor(itinerary.overallSafetyScore);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: safetyColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: safetyColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Safety',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${itinerary.overallSafetyScore.round()}/100',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: safetyColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: safetyColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          itinerary.safetyStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(itinerary.formattedTotalTime),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(itinerary.formattedTotalDistance),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSegment(SafeRoute route) {
    final safetyColor = _getSafetyColor(route.safetyScore);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: safetyColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_downward, color: safetyColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: safetyColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${route.safetyScore.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      route.formattedDuration,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      route.formattedDistance,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (route.dangerZonesCrossed.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '⚠️ Crosses ${route.dangerZonesCrossed.length} danger zone(s)',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopCard(ItineraryStop stop, int number) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          stop.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(stop.category),
        trailing: IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _removeStop(stop.id),
        ),
      ),
    );
  }

  Widget _buildRecommendations(DayItinerary itinerary) {
    final recommendations = _itineraryService.getRecommendations();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(top: BorderSide(color: Colors.blue[200]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(child: Text(rec, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
