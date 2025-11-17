import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/incident_service.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool chatbotOpen = false;
  Position? _currentPosition;
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _initLocationAndData();
  }

  Future<void> _initLocationAndData() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentPosition = pos;
      });

      // Load incidents from local storage to show markers
      final incidents = await IncidentService.getAllIncidents();
      for (var inc in incidents) {
        if (inc['location'] != null) {
          final lat = (inc['location']['latitude'] as num).toDouble();
          final lng = (inc['location']['longitude'] as num).toDouble();
          _markers.add(Marker(
            markerId: MarkerId(inc['id'] ?? DateTime.now().toIso8601String()),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: inc['title'] ?? 'Incident', snippet: inc['category']),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));
        }
      }

      // Predefined geofence circles
      _circles.addAll([
        Circle(
          circleId: const CircleId('remote_forest'),
          center: LatLng(pos.latitude + 0.01, pos.longitude + 0.02),
          radius: 2000, // meters
          fillColor: Colors.red.withOpacity(0.1),
          strokeColor: Colors.red.withOpacity(0.6),
        ),
        Circle(
          circleId: const CircleId('market_area'),
          center: LatLng(pos.latitude + 0.002, pos.longitude + 0.005),
          radius: 800,
          fillColor: Colors.orange.withOpacity(0.1),
          strokeColor: Colors.orange.withOpacity(0.6),
        ),
        Circle(
          circleId: const CircleId('industrial_zone'),
          center: LatLng(pos.latitude - 0.012, pos.longitude - 0.01),
          radius: 1500,
          fillColor: Colors.purple.withOpacity(0.08),
          strokeColor: Colors.purple.withOpacity(0.6),
        ),
      ]);
      setState(() {});
    } catch (e) {
      // ignore
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Header with Profile
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            child: const Text('RK'),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rajesh Kumar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'ID: TID-2025-001234',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Stack(
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            size: 28,
                            color: Colors.grey,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Safety Score Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.grey[800]),
                          const SizedBox(width: 8),
                          const Text(
                            'Tourist Safety Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '87',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[600],
                              ),
                            ),
                            const Text(
                              'Out of 100',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSafetyItem('Current Zone', 'SAFE', Colors.green),
                      const SizedBox(height: 12),
                      _buildSafetyItem('Time', '17:15 PM', Colors.grey),
                      const SizedBox(height: 12),
                      _buildSafetyItem('Crowd Density', 'MEDIUM', Colors.orange),
                      const SizedBox(height: 12),
                      _buildSafetyItem('Weather', 'Clear', Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Map Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text(
                            'Your Location & Nearby Zones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Map
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: _currentPosition == null
                              ? const Center(child: CircularProgressIndicator())
                              : GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                    zoom: 14,
                                  ),
                                  myLocationEnabled: true,
                                  myLocationButtonEnabled: false,
                                  markers: _markers,
                                  circles: _circles,
                                  onMapCreated: (controller) {
                                    _mapController = controller;
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Current Location
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.my_location, color: Colors.green[600]),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Location',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Nashik, Maharashtra',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Nearby Zones',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildNearbyZone('Tourist Zone', '0.2 km', 'SAFE', Colors.green),
                      const SizedBox(height: 8),
                      _buildNearbyZone('Market Area', '0.5 km', 'CAUTION', Colors.orange),
                      const SizedBox(height: 8),
                      _buildNearbyZone('Remote forest', '2.1 km', 'Danger', Colors.red),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Active Alerts
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.black87),
                              const SizedBox(width: 8),
                              const Text(
                                'Active Alerts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '3',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildAlert('Zone Alert', 'Warning', Colors.orange, 'Approaching caution zone - Market Area', '2 min ago'),
                      const SizedBox(height: 10),
                      _buildAlert('Security Alert', 'Danger', Colors.red, 'Avoid remote forest area - increased risk level', '1 hour ago'),
                      const SizedBox(height: 10),
                      _buildAlert('Weather Update', 'Info', Colors.blue, 'Heavy rainfall expected in 1 hour', '15 min ago'),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Chatbot Button
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.blue[800],
              onPressed: () {
                setState(() {
                  chatbotOpen = !chatbotOpen;
                });
              },
              child: Stack(
                children: [
                  const Icon(Icons.smart_toy_outlined),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '1',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom navigation is managed by `MainNavigationScreen` in `main.dart`.
    );
  }

  Widget _buildSafetyItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, size: 8),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildNearbyZone(String name, String distance, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  distance,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlert(String title, String badge, Color badgeColor, String message, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: badgeColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
