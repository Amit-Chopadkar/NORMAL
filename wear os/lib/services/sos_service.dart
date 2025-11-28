import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_alert.dart';
import 'api_service.dart';
import 'location_service.dart';
import 'notification_service.dart';

class SOSService {
  static Timer? _countdownTimer;
  static bool _isCountingDown = false;
  static int _countdown = 3;
  static final List<Function(int)> _countdownListeners = [];
  static final List<Function(String, bool)> _resultListeners = [];

  // Start SOS with countdown
  static void startSOSCountdown() {
    if (_isCountingDown) return;

    _isCountingDown = true;
    _countdown = 3;

    // Notify listeners
    _notifyCountdownListeners(_countdown);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      _notifyCountdownListeners(_countdown);

      if (_countdown <= 0) {
        timer.cancel();
        _sendSOS();
        _isCountingDown = false;
      }
    });

    // Vibrate to indicate start
    NotificationService.vibrate(1);
  }

  // Cancel countdown
  static void cancelCountdown() {
    _countdownTimer?.cancel();
    _isCountingDown = false;
    _countdown = 3;
    _notifyCountdownListeners(-1); // -1 indicates cancelled
    NotificationService.cancel();
  }

  // Send SOS alert
  static Future<void> _sendSOS() async {
    try {
      // Strong vibration to indicate sending
      await NotificationService.vibrate(3);

      // Get current location
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _notifyResultListeners('Could not get location', false);
        return;
      }

      // Get user ID from preferences (or use device ID)
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'watch-user-${DateTime.now().millisecondsSinceEpoch}';

      // Create SOS alert
      final alert = SOSAlert(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        message: 'Emergency SOS from Watch',
        timestamp: DateTime.now(),
      );

      // Send to backend with retry
      final result = await ApiService.sendSOSAlertWithRetry(alert);

      if (result['success'] == true) {
        // Save last SOS time
        await prefs.setString('lastSOSTime', DateTime.now().toIso8601String());
        
        _notifyResultListeners('SOS Sent Successfully!', true);
      } else {
        _notifyResultListeners(
          'Failed to send SOS: ${result['error']}',
          false,
        );
      }
    } catch (e) {
      _notifyResultListeners('Error: $e', false);
    }
  }

  // Add countdown listener
  static void addCountdownListener(Function(int) listener) {
    _countdownListeners.add(listener);
  }

  // Add result listener
  static void addResultListener(Function(String, bool) listener) {
    _resultListeners.add(listener);
  }

  // Remove listeners
  static void removeCountdownListener(Function(int) listener) {
    _countdownListeners.remove(listener);
  }

  static void removeResultListener(Function(String, bool) listener) {
    _resultListeners.remove(listener);
  }

  // Notify countdown listeners
  static void _notifyCountdownListeners(int count) {
    for (var listener in _countdownListeners) {
      listener(count);
    }
  }

  // Notify result listeners
  static void _notifyResultListeners(String message, bool success) {
    for (var listener in _resultListeners) {
      listener(message, success);
    }
  }

  // Check if currently counting down
  static bool get isCountingDown => _isCountingDown;

  // Get current countdown value
  static int get currentCountdown => _countdown;

  // Get last SOS time
  static Future<DateTime?> getLastSOSTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString('lastSOSTime');
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Cleanup
  static void dispose() {
    _countdownTimer?.cancel();
    _countdownListeners.clear();
    _resultListeners.clear();
  }
}
