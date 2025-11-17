import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'incident_report_screen.dart';
import '../services/chat_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _sosActive = false;

  Future<void> _callEmergency(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch call: $e')),
        );
      }
    }
  }

  Future<void> _triggerSOS() async {
    setState(() => _sosActive = true);

    try {
      final Position pos = await Geolocator.getCurrentPosition();

      // Emit SOS alert via Socket.io to admin dashboard
      ChatService.sendMessage(
        'SOS_ALERT:${pos.latitude},${pos.longitude}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert sent to authorities with your location!'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _sosActive = false);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS Error: $e')),
        );
        setState(() => _sosActive = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency'),
        centerTitle: true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.red[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // SOS Button
              Container(
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _sosActive ? Colors.orange[600] : Colors.red,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: _triggerSOS,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emergency, size: 64, color: Colors.white),
                        const SizedBox(height: 8),
                        Text(
                          _sosActive ? 'SENDING...' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _sosActive ? 'Alert sent!' : 'Tap to send',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Emergency Services
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildEmergencyContact('Police', '100', Colors.blue, () => _callEmergency('100')),
              const SizedBox(height: 12),
              _buildEmergencyContact('Ambulance', '102', Colors.green, () => _callEmergency('102')),
              const SizedBox(height: 12),
              _buildEmergencyContact('Fire Department', '101', Colors.orange, () => _callEmergency('101')),
              const SizedBox(height: 12),
              _buildEmergencyContact('Local Police Station', '+91 2560 234567', Colors.indigo, () => _callEmergency('+912560234567')),
              const SizedBox(height: 32),
              // Share Location Button
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    final String location = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
                    await launchUrl(Uri.parse(location));
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.location_on),
                label: const Text('Share My Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              // Report Incident Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IncidentReportScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.report_problem),
                label: const Text('Report Incident'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number, Color color, VoidCallback onCall) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.phone, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    number,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: onCall,
            icon: Icon(Icons.call, color: color),
          ),
        ],
      ),
    );
  }
}
