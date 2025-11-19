import 'package:flutter/material.dart';
class NotificationService {
  static Future<void> initialize() async {
    // Notifications plugin temporarily disabled for local build.
    // In production, re-enable `flutter_local_notifications` and restore initialization.
    debugPrint('NotificationService initialized (stub)');
  }

  static Future<void> showAlertNotification({required String title, required String body, required String type}) async {
    debugPrint('AlertNotification: $title - $body ($type)');
  }

  static Future<void> showEmergencyNotification() async {
    debugPrint('Emergency notification triggered (stub)');
  }
}