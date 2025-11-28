import 'package:flutter/material.dart';
import '../models/zone_alert.dart';
import '../services/sos_service.dart';

class ZoneAlertScreen extends StatelessWidget {
  final ZoneAlert alert;

  const ZoneAlertScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (alert.zone.type) {
      case 'danger':
        backgroundColor = Colors.red.shade900;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case 'caution':
        backgroundColor = Colors.orange.shade900;
        textColor = Colors.white;
        icon = Icons.error_outline;
        break;
      case 'safe':
      default:
        backgroundColor = Colors.green.shade900;
        textColor = Colors.white;
        icon = Icons.check_circle_outline;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Icon(
                icon,
                size: 48,
                color: textColor,
              ),

              const SizedBox(height: 16),

              // Zone name
              Text(
                alert.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Risk level
              Text(
                alert.message,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Quick SOS button for danger zones
              if (alert.zone.riskLevel == 'high')
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    SOSService.startSOSCountdown();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Send SOS'),
                ),

              const SizedBox(height: 16),

              // Dismiss button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Acknowledge',
                  style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
