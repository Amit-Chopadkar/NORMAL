import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'incident_report_screen.dart';
import '../services/location_service.dart';
import '../services/localization_service.dart';

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
      await FirebaseFirestore.instance.collection('alerts').add({
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
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildSOSButton(),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        tr('emergency_contacts_title'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildContactsGrid(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipPath(
          clipper: HeaderClipper(),
          child: Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF7B61FF), // Purple
                  Color(0xFF6C5DD3),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 50), // Increased spacing since notch is gone
                  Text(
                    'Are you in emergency',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Press the button below help will reach you soon',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _sosPressed ? Colors.green : const Color(0xFFEF4444), // Red or Green
          boxShadow: [
            BoxShadow(
              color: (_sosPressed ? Colors.green : const Color(0xFFEF4444)).withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 15,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 0,
              spreadRadius: -15,
            ),
          ],
          border: Border.all(
            color: _sosPressed ? Colors.green.shade100 : Colors.red.shade100,
            width: 20,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _sosPressed ? tr('alert_sent') : tr('sos'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactsGrid() {
    final contacts = [
      {
        'name': tr('police'),
        'icon': Icons.local_police_outlined,
        'color': const Color(0xFF7B61FF),
        'number': '100'
      },
      {
        'name': tr('fire'), // Was 'Firefighters' in design, but tr('fire') in original
        'icon': Icons.local_fire_department_outlined,
        'color': const Color(0xFF7B61FF),
        'number': '101'
      },
      {
        'name': tr('ambulance'),
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF7B61FF),
        'number': '102'
      },
      {
        'name': 'Local Police', // Original had 'Local Police Station' hardcoded too
        'icon': Icons.local_taxi_outlined,
        'color': const Color(0xFF7B61FF),
        'number': '+91 2560 234567'
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 2.5,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return InkWell(
          onTap: () => _makeEmergencyCall(contact['number'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (contact['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    contact['icon'] as IconData,
                    color: contact['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    contact['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          tr('call_police'),
          Icons.phone_in_talk,
          const Color(0xFFEF4444),
          () => _makeEmergencyCall('100'),
        ),
        const SizedBox(height: 15),
        _buildActionButton(
          tr('report_incident'),
          Icons.warning_amber_rounded,
          const Color(0xFFF59E0B),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IncidentReportScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 15),
        _buildActionButton(
          tr('share_location'),
          Icons.location_on_outlined,
          const Color(0xFF7B61FF),
          () {
            // Existing logic for location sharing
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            tr('sos_alert'),
            style: const TextStyle(color: Colors.red),
          ),
          content: Text(
            tr('sos_alert_message'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel')),
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
              child: Text(tr('send_sos_alert')),
            ),
          ],
        );
      },
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 50);
    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 4), size.height);
    var secondEndPoint = Offset(size.width, size.height - 50);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

