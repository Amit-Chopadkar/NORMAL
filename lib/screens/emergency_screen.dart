import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'incident_report_screen.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../services/localization_service.dart';
import '../services/api_service.dart';
import '../services/api_environment.dart';
import '../services/backend_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  bool _sosPressed = false;
  late final stt.SpeechToText _speechToText;
  bool _speechEnabled = false;
  bool _isListeningForHelp = false;
  DateTime? _lastVoiceTrigger;

  // Map related
  GoogleMapController? _mapController;
  LatLng? _incidentLocation;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initVoiceRecognition();
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }

  Future<void> _initVoiceRecognition() async {
    try {
      final hasSpeech = await _speechToText.initialize(
        onError: (errorNotification) => _handleSpeechError(errorNotification.errorMsg),
        onStatus: _handleSpeechStatus,
      );
      if (!mounted) return;
      setState(() {
        _speechEnabled = hasSpeech;
      });
      if (hasSpeech) {
        _startListeningForHelp();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  Future<void> _startListeningForHelp() async {
    if (!_speechEnabled || _isListeningForHelp) return;
    await _speechToText.listen(
      onResult: _handleSpeechResult,
      pauseFor: const Duration(seconds: 10),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );
    if (!mounted) return;
    setState(() {
      _isListeningForHelp = _speechToText.isListening;
    });
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    try {
      final recognized = result.recognizedWords.trim().toLowerCase();
      if (recognized.isEmpty) {
        return;
      }

      const keywords = ['help', 'please help', 'i need help', 'sos'];
      final matchedKeyword =
          keywords.firstWhere((kw) => recognized.contains(kw), orElse: () => '');
      final now = DateTime.now();
      final recentlyTriggered = _lastVoiceTrigger != null &&
          now.difference(_lastVoiceTrigger!) < const Duration(seconds: 4);

      print('[SOS] Recognized "$recognized" | keyword: $matchedKeyword | confidence: ${result.confidence}');

      if (matchedKeyword.isEmpty || recentlyTriggered) {
        return;
      }

      if (result.hasConfidenceRating && result.confidence < 0.4) {
        print('[SOS] Ignoring low-confidence match');
        return;
      }

      _lastVoiceTrigger = now;
      _handleVoiceTriggeredSOS();
    } catch (e) {
      print('[SOS] Error handling speech result: $e');
    }
  }

  void _handleSpeechError(String message) {
    if (!mounted) return;
    setState(() {
      _isListeningForHelp = false;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _startListeningForHelp();
      }
    });
  }

  void _handleSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'done' || status == 'notListening') {
      setState(() {
        _isListeningForHelp = false;
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _startListeningForHelp();
        }
      });
    }
  }

  void _handleVoiceTriggeredSOS() {
    if (!mounted) return;
    print('[SOS] Voice trigger detected, calling _sendSOSAlert');
    _sendSOSAlert();
    setState(() {
      print('[SOS] setState: _sosPressed = true');
      _sosPressed = true;
    });
    // Reset button after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          print('[SOS] setState: _sosPressed = false');
          _sosPressed = false;
        });
      }
    });
  }

  Future<void> _sendSOSAlert() async {
    print('[SOS] _sendSOSAlert called');
    // Get Emergency Contacts first (fast, no network)
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final contacts = authProvider.emergencyContacts;
    
    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No emergency contacts found. Please add them in Profile.')),
        );
      }
      return;
    }

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🆘 Sending SOS Alert...'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }

    // Get location with timeout (don't block on slow GPS)
    Position? position;
    try {
      position = await LocationService.getCurrentLocation()
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      print('Location timeout or error: $e');
      // Try to get last known position as fallback
      try {
        position = await Geolocator.getLastKnownPosition()
            .timeout(const Duration(milliseconds: 500));
      } catch (e2) {
        print('No last known position: $e2');
        // Continue without location - still send SOS
      }
    }

    // Build message with available location
    String locationUrl = 'Location unavailable';
    double? lat, lng;
    if (position != null) {
      lat = position.latitude;
      lng = position.longitude;
      locationUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      // Set incident location for geofence
      if (lat != null && lng != null) {
        final double latValue = lat;
        final double lngValue = lng;
        setState(() {
          _incidentLocation = LatLng(latValue, lngValue);
        });
      }
    }

    final phoneNumbers = contacts.map((e) => e['phone']).join(',');
    final message = position != null
        ? '🆘 SOS! I need immediate help!\n\nMy location: $locationUrl\nCoordinates: $lat, $lng\nTime: ${DateTime.now().toString()}\n\nPlease respond immediately!'
        : '🆘 SOS! I need immediate help!\n\nTime: ${DateTime.now().toString()}\n\nPlease respond immediately!';
    
    // OPEN SMS APP IMMEDIATELY (don't wait for backend)
    try {
      final smsUri = Uri.parse('sms:$phoneNumbers?body=${Uri.encodeComponent(message)}');
      print('[SOS] Sending SMS with URI: $smsUri');
      await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      print('[SOS] SMS intent launched');
    } catch (e) {
      print('[SOS] Error opening SMS app: $e');
    }

    // Run backend operations in background (non-blocking)
    if (position != null) {
      _sendSOSBackground(
        latitude: position.latitude,
        longitude: position.longitude,
        contacts: contacts,
        userName: authProvider.user?.name ?? authProvider.user?.email,
      );
    } else {
      // Still try to send to Firestore even without location
      _sendSOSBackground(
        latitude: null,
        longitude: null,
        contacts: contacts,
        userName: authProvider.user?.name ?? authProvider.user?.email,
      );
    }
  }

  // Background task - doesn't block UI
  void _sendSOSBackground({
    required double? latitude,
    required double? longitude,
    required List<Map<String, dynamic>> contacts,
    String? userName,
  }) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id ?? 'unknown';
      
      // Send alert to new backend API (fire and forget - no await)
      if (latitude != null && longitude != null) {
        // Check if user is authenticated with new backend
        final isAuthenticated = await BackendService.isAuthenticated();
        if (isAuthenticated) {
          unawaited(() async {
            try {
              await BackendService.createAlert(
                alertType: 'sos',
                lat: latitude,
                lng: longitude,
                message: 'SOS Alert from ${userName ?? "User"}',
              ).timeout(const Duration(seconds: 5));
            } catch (error) {
              print('New backend alert error (non-critical): $error');
            }
          }());
        }
        
        // Also send to old backend (fire and forget - no await)
        unawaited(() async {
          try {
            await ApiService.sendSOS(
              latitude: latitude,
              longitude: longitude,
              emergencyContacts: contacts,
              userName: userName,
            ).timeout(const Duration(seconds: 5));
          } catch (error) {
            print('Backend SMS error (non-critical): $error');
          }
        }());
      }

      // Send to Firestore (fire and forget - no await)
      unawaited(() async {
        try {
          await FirebaseFirestore.instance.collection('alerts').add({
            'alert_type': 'SOS',
            if (latitude != null && longitude != null) 'location': {
              'latitude': latitude,
              'longitude': longitude,
              'timestamp': DateTime.now(),
              'type': 'SOS',
            },
            'user_id': userId,
            'timestamp': DateTime.now(),
            'status': 'active',
            'contacts_notified': contacts.length,
          }).timeout(const Duration(seconds: 3));
        } catch (error) {
          print('Firestore error (non-critical): $error');
        }
      }());
    } catch (e) {
      // All background errors are non-critical
      print('Background SOS task error: $e');
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
                const SizedBox(height: 12),
                _buildVoiceStatusBanner(),
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
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF2196F3), // Blue
                  Color(0x801976D2), // Darker Blue with fade (50% opacity)
                  Color(0x001976D2), // Fully transparent for fade effect
                ],
                stops: [0.0, 0.7, 1.0],
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

  Widget _buildVoiceStatusBanner() {
    Color statusColor;
    IconData icon;
    String label;

    if (!_speechEnabled) {
      statusColor = Colors.grey;
      icon = Icons.mic_off;
      label = tr('voice_control_unavailable');
    } else if (_isListeningForHelp) {
      statusColor = Colors.green;
      icon = Icons.hearing;
      label = tr('voice_control_listening');
    } else {
      statusColor = Colors.orange;
      icon = Icons.mic;
      label = tr('voice_control_ready');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsGrid() {
    final contacts = [
      {
        'name': tr('police'),
        'icon': Icons.local_police_outlined,
        'color': const Color(0xFF2196F3), // Blue
        'number': '100'
      },
      {
        'name': tr('fire'),
        'icon': Icons.local_fire_department_outlined,
        'color': const Color(0xFF2196F3), // Blue
        'number': '101'
      },
      {
        'name': tr('ambulance'),
        'icon': Icons.medical_services_outlined,
        'color': const Color(0xFF2196F3), // Blue
        'number': '102'
      },
      {
        'name': 'Local Police',
        'icon': Icons.local_taxi_outlined,
        'color': const Color(0xFF2196F3), // Blue
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
    TextEditingController _vehicleController = TextEditingController();
    return Column(
      children: [
        Container(
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
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_car, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: TextField(
                  controller: _vehicleController,
                  decoration: InputDecoration(
                    labelText: 'Enter your vehicle number',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
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
        // ...existing code...
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

  void _showSOSConfirmDialog({bool triggeredByVoice = false}) {
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
            triggeredByVoice
                ? tr('voice_sos_alert_message')
                : tr('sos_alert_message'),
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

