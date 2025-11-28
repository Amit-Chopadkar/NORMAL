import 'package:flutter/material.dart';

import '../services/sos_service.dart';
import '../services/zone_service.dart';
import '../models/zone.dart';
import '../models/zone_alert.dart';
import 'zone_alert_screen.dart';
import 'confirmation_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _countdown = 3;
  bool _isCountingDown = false;
  Zone? _currentZone;

  @override
  void initState() {
    super.initState();
   
    // Listen to SOS countdown
    SOSService.addCountdownListener(_onCountdownUpdate);
    SOSService.addResultListener(_onSOSResult);

    // Listen to zone alerts
    ZoneService.addAlertListener(_onZoneAlert);

    // Start zone monitoring
    ZoneService.startMonitoring();
  }

  @override
  void dispose() {
    SOSService.removeCountdownListener(_onCountdownUpdate);
    SOSService.removeResultListener(_onSOSResult);
    ZoneService.removeAlertListener(_onZoneAlert);
    super.dispose();
  }

  void _onCountdownUpdate(int count) {
    if (!mounted) return;
    setState(() {
      if (count == -1) {
        // Cancelled
        _isCountingDown = false;
        _countdown = 3;
      } else {
        _countdown = count;
        _isCountingDown = count > 0;
      }
    });
  }

  void _onSOSResult(String message, bool success) {
    if (!mounted) return;
    
    // Navigate to confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          message: message,
          success: success,
        ),
      ),
    );
  }

  void _onZoneAlert(ZoneAlert alert) {
    if (!mounted) return;

    // Update current zone
    setState(() {
      _currentZone = ZoneService.getCurrentZone();
    });

    // Show zone alert screen for zone entry (not for approaching)
    if (alert.eventType == 'entering') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ZoneAlertScreen(alert: alert),
        ),
      );
    }
  }

  void _onSOSPressed() {
    if (_isCountingDown) {
      // Cancel countdown
      SOSService.cancelCountdown();
    } else {
      // Start countdown
      SOSService.startSOSCountdown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Zone indicator
              if (_currentZone != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildZoneIndicator(),
                ),

              // SOS Button
              GestureDetector(
                onTap: _onSOSPressed,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isCountingDown ? Colors.orange : Colors.red,
                    boxShadow: [
                      BoxShadow(
                        color: (_isCountingDown ? Colors.orange : Colors.red)
                            .withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isCountingDown ? '$_countdown' : 'SOS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isCountingDown)
                          const Text(
                            'Tap to Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Status text
              Text(
                _isCountingDown
                    ? 'Sending SOS...'
                    : 'Tap for Emergency',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

              // Settings button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.white54),
                iconSize: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildZoneIndicator() {
    if (_currentZone == null) return const SizedBox.shrink();

    Color zoneColor;
    switch (_currentZone!.type) {
      case 'danger':
        zoneColor = Colors.red;
        break;
      case 'caution':
        zoneColor = Colors.orange;
        break;
      case 'safe':
      default:
        zoneColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: zoneColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zoneColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 12,
            color: zoneColor,
          ),
          const SizedBox(width: 4),
          Text(
            _currentZone!.name,
            style: TextStyle(
              color: zoneColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
