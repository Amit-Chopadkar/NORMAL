import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'incident_report_screen.dart';
import '../services/location_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _sosPressed = false;

  Future<void> _sendSOSAlert() async {
    try {
      // Get current location
      final position = await LocationService.getCurrentLocation();
      final location = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now(),
        'type': 'SOS',
      };

      // Send SOS alert to Firestore admin dashboard
      await FirebaseFirestore.instance
          .collection('alerts')
          .add({
        'alert_type': 'SOS',
        'location': location,
        'user_id': 'current_user_id',
        'timestamp': DateTime.now(),
        'status': 'active',
      });

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS Alert Sent to Emergency Services!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SOS: $e')),
        );
      }
    }
  }

  Future<void> _makeEmergencyCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    try {
      // Try to launch with tel: scheme
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching dialer: $e')),
        );
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
              // SOS Button with Animation
              _buildSOSButton(),
              const SizedBox(height: 32),
              // Emergency Services
              const Text(
                'Emergency Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildEmergencyContact('Police', '100', Colors.blue),
              const SizedBox(height: 12),
              _buildEmergencyContact('Ambulance', '102', Colors.green),
              const SizedBox(height: 12),
              _buildEmergencyContact('Fire Department', '101', Colors.orange),
              const SizedBox(height: 12),
              _buildEmergencyContact('Local Police Station', '+91 2560 234567', Colors.indigo),
              const SizedBox(height: 32),
              // Share Location Button
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.location_on),
                label: const Text('Share My Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              // Call Police Button
              ElevatedButton.icon(
                onPressed: () {
                  _makeEmergencyCall('100');
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Police'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
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

  Widget _buildSOSButton() {
    return GestureDetector(
      onTap: () {
        if (!_sosPressed) {
          _showSOSConfirmDialog();
        }
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _sosPressed ? Colors.green : Colors.red,
          boxShadow: [
            BoxShadow(
              color: (_sosPressed ? Colors.green : Colors.red).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _sosPressed ? Icons.check_circle : Icons.emergency,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                _sosPressed ? 'ALERT SENT' : 'SOS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _sosPressed ? 'Emergency Services Notified' : 'Press to Send Alert',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String name, String number, Color color) {
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
            onPressed: () {
              _makeEmergencyCall(number);
            },
            icon: Icon(Icons.call, color: color),
          ),
        ],
      ),
    );
  }

  void _showSOSConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SOS Alert', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Are you in immediate danger? This will send an alert to emergency services and your emergency contacts with your current location.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendSOSAlert();
                setState(() {
                  _sosPressed = true;
                });
                // Reset button after 5 seconds
                Future.delayed(const Duration(seconds: 5), () {
                  if (mounted) {
                    setState(() {
                      _sosPressed = false;
                    });
                  }
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Send SOS Alert'),
            ),
          ],
        );
      },
    );
  }
}
