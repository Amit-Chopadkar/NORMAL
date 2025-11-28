import 'zone.dart';

class ZoneAlert {
  final Zone zone;
  final String eventType; // 'entering', 'approaching', 'exiting'
  final double distance;
  final DateTime timestamp;
  final bool acknowledged;

  ZoneAlert({
    required this.zone,
    required this.eventType,
    required this.distance,
    required this.timestamp,
    this.acknowledged = false,
  });

  String get title {
    switch (eventType) {
      case 'entering':
        return 'Entering ${zone.name}';
      case 'approaching':
        return 'Approaching ${zone.name}';
      case 'exiting':
        return 'Leaving ${zone.name}';
      default:
        return zone.name;
    }
  }

  String get message {
    switch (eventType) {
      case 'entering':
        return 'Risk Level: ${zone.riskLevel.toUpperCase()}';
      case 'approaching':
        return '${distance.toInt()}m away - Caution advised';
      case 'exiting':
        return 'You have left the zone';
      default:
        return '';
    }
  }

  int get vibrationPattern {
    if (eventType == 'approaching') return 1;
    switch (zone.riskLevel) {
      case 'high':
        return 3; // 3 pulses for danger
      case 'medium':
        return 2; // 2 pulses for caution
      default:
        return 1; // 1 pulse for safe
    }
  }

  ZoneAlert copyWith({bool? acknowledged}) {
    return ZoneAlert(
      zone: zone,
      eventType: eventType,
      distance: distance,
      timestamp: timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
    );
  }
}
