import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/safe_route_model.dart';
import '../services/safe_routing_service.dart';
import '../widgets/offline_map_widget.dart';

/// Screen for planning safety-aware routes
class RoutePlanningScreen extends StatefulWidget {
  final LatLng? initialDestination;

  const RoutePlanningScreen({
    Key? key,
    this.initialDestination,
  }) : super(key: key);

  @override
  State<RoutePlanningScreen> createState() => _RoutePlanningScreenState();
}

class _RoutePlanningScreenState extends State<RoutePlanningScreen> {
  Position? _currentPosition;
  LatLng? _destination;
  SafeRouteResponse? _routeResponse;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _destination = widget.initialDestination;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _calculateRoute() async {
    if (_currentPosition == null || _destination == null) {
      setState(() {
        _error = 'Please set both origin and destination';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final origin = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      
      final response = await SafeRoutingService.calculateSafeRoute(
        origin: origin,
        destination: _destination!,
      );

      setState(() {
        _routeResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to calculate route: $e';
        _isLoading = false;
      });
    }
  }

  void _launchGoogleMaps() async {
    if (_destination == null) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${_destination!.latitude},${_destination!.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Color _getSafetyColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safe Route Planning'),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Map view
          if (_currentPosition != null)
            OfflineMapWidget(
              center: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 13.0,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationEnabled: true,
              currentLocation: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Route info card
          if (_routeResponse != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: _buildRouteCard(),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Calculating safe route...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_error != null && !_isLoading)
            Positioned(
              top: 20,
              left: 16,
              right: 16,
              child: Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => _error = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _destination != null && _currentPosition != null
          ? FloatingActionButton.extended(
              onPressed: _calculateRoute,
              icon: const Icon(Icons.route),
              label: const Text('Calculate Route'),
            )
          : null,
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 40),
        ),
      );
    }

    // Destination marker
    if (_destination != null) {
      markers.add(
        Marker(
          point: _destination!,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (_routeResponse == null) return [];

    final route = _routeResponse!.recommendedRoute;
    final color = _getSafetyColor(route.safetyScore);

    return [
      Polyline(
        points: route.coordinates,
        strokeWidth: 4.0,
        color: color,
      ),
    ];
  }

  Widget _buildRouteCard() {
    final route = _routeResponse!.recommendedRoute;
    final safetyColor = _getSafetyColor(route.safetyScore);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safety score badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: safetyColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Safety: ${route.safetyScore.round()}/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  route.safetyStatus,
                  style: TextStyle(
                    color: safetyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Route details
            Row(
              children: [
                Icon(Icons.straighten, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(route.formattedDistance, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(route.formattedDuration, style: const TextStyle(fontSize: 14)),
              ],
            ),
            
            // Danger zones warning
            if (route.totalDangerZones > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Crosses ${route.totalDangerZones} danger zone(s)',
                        style: const TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchGoogleMaps,
                icon: const Icon(Icons.navigation),
                label: const Text('Start Navigation in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
