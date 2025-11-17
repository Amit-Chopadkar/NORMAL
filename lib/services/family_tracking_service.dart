import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'chat_service.dart';

class FamilyTrackingService {
  static Timer? _timer;
  static bool _running = false;

  // Start sending location updates every [intervalSeconds]
  static Future<void> start({int intervalSeconds = 15}) async {
    if (_running) return;
    _running = true;

    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
      try {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
        final data = {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        };
        try {
          ChatService.socket.emit('locationUpdate', data);
        } catch (e) {
          // ignore socket errors
        }
      } catch (e) {
        // permission or location error
      }
    });
  }

  static Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  static bool isRunning() => _running;
}
