class SOSAlert {
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String message;
  final DateTime timestamp;
  final String? currentZone;

  SOSAlert({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.message,
    required this.timestamp,
    this.currentZone,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'currentZone': currentZone,
    };
  }

  factory SOSAlert.fromJson(Map<String, dynamic> json) {
    return SOSAlert(
      userId: json['userId'] ?? 'unknown',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      message: json['message'] ?? 'SOS Alert',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      currentZone: json['currentZone'],
    );
  }
}
