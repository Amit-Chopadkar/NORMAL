import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _sosMarkers = {};
  final Set<Marker> _incidentMarkers = {};
  int _activeSOS = 0;
  int _totalIncidents = 0;
  int _activeUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    // TODO: Load from backend /api/admin/incidents, /api/admin/users, /api/admin/active-sos
    setState(() {
      _activeSOS = 3;
      _totalIncidents = 24;
      _activeUsers = 156;

      // Sample SOS markers
      _sosMarkers.add(
        Marker(
          markerId: MarkerId('sos1'),
          position: LatLng(20.0112, 73.7909),
          infoWindow: InfoWindow(title: 'SOS Alert', snippet: 'Tourist - Female, Age 28'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      // Sample incident markers
      _incidentMarkers.add(
        Marker(
          markerId: MarkerId('inc1'),
          position: LatLng(20.0150, 73.8000),
          infoWindow: InfoWindow(title: 'Suspicious Activity', snippet: 'Market Area'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Stats Cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Active SOS', _activeSOS.toString(), Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Incidents', _totalIncidents.toString(), Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Users Online', _activeUsers.toString(), Colors.green),
                  ),
                ],
              ),
            ),
            // Map View
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 300,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(20.0112, 73.7909),
                    zoom: 14,
                  ),
                  markers: {..._sosMarkers, ..._incidentMarkers},
                  onMapCreated: (controller) => _mapController = controller,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Live SOS Alerts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live SOS Alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSOSAlert(
                    'ID: SOS-001',
                    'Female, Age 28',
                    'Market Area',
                    '5 mins ago',
                    Colors.red,
                  ),
                  _buildSOSAlert(
                    'ID: SOS-002',
                    'Male, Age 35',
                    'Tourist Zone',
                    '12 mins ago',
                    Colors.orange,
                  ),
                  _buildSOSAlert(
                    'ID: SOS-003',
                    'Female, Age 22',
                    'Pandavleni Caves',
                    '23 mins ago',
                    Colors.yellow[700]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Recent Incidents
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Incidents',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildIncidentTile('Pickpocketing', 'Market Area', 'HIGH', Colors.red),
                  _buildIncidentTile('Harassment', 'Bus Station', 'MEDIUM', Colors.orange),
                  _buildIncidentTile('Lost Tourist', 'Sula Vineyards', 'MEDIUM', Colors.orange),
                  _buildIncidentTile('Fake Guide', 'Tourist Zone', 'LOW', Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSOSAlert(String id, String user, String location, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text('$user • $location', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            onPressed: () {},
            child: const Text('Respond', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTile(String title, String location, String severity, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
            child: Text(severity, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
