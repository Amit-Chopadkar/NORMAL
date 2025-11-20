import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final MethodChannel _platform = MethodChannel('tourapp/notifications');

  static Future<void> initialize() async {
    // Keep init lightweight — platform channel is handled in native MainActivity
    debugPrint('NotificationService initialized (platform channel)');
  }

  static Future<void> showAlertNotification({required String title, required String body, required String type}) async {
    try {
      await _platform.invokeMethod('showNotification', {'title': title, 'body': body});
    } catch (e) {
      debugPrint('Platform channel notification failed: $e');
    }
  }

  static Future<void> showEmergencyNotification() async {
    await showAlertNotification(title: 'Emergency', body: 'Emergency triggered', type: 'emergency');
  }
}