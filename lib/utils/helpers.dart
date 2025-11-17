import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  static Color getAlertColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  static Color getAlertBackgroundColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange[50]!;
      case 'danger':
        return Colors.red[50]!;
      case 'info':
        return Colors.blue[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  static String getSafetyStatus(int score) {
    if (score >= 80) return 'SAFE';
    if (score >= 60) return 'MODERATE';
    if (score >= 40) return 'CAUTION';
    return 'DANGER';
  }

  static Color getSafetyColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.yellow;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  static String formatPhoneNumber(String phone) {
    // Simple phone formatting
    if (phone.length == 10) {
      return '${phone.substring(0, 5)} ${phone.substring(5)}';
    }
    return phone;
  }

  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Future<void> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required Function onConfirm,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }
}