class Zone {
  final String id;
  final String name;
  final String type;
  final String riskLevel;
  final double latitude;
  final double longitude;
  final double radius;
  final String? color;

  Zone({
    required this.id,
    required this.name,
    required this.type,
    required this.riskLevel,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.color,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    return Zone(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown Zone',
      type: json['type'] ?? 'caution',
      riskLevel: json['riskLevel'] ?? 'medium',
      latitude: (json['lat'] ?? json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['lng'] ?? json['longitude'] ?? 0.0).toDouble(),
      radius: (json['radius'] ?? 500.0).toDouble(),
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'riskLevel': riskLevel,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'color': color,
    };
  }

  String get colorHex {
    if (color != null) return color!;
    switch (type) {
      case 'safe':
        return '#22c55e';
      case 'danger':
        return '#ef4444';
      case 'caution':
      default:
        return '#eab308';
    }
  }

  String get displayType {
    switch (type) {
      case 'safe':
        return 'SAFE';
      case 'danger':
        return 'DANGER';
      case 'caution':
      default:
        return 'CAUTION';
    }
  }
}
