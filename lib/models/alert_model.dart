import 'package:flutter/material.dart';

class Alert {
  final String id;
  final String type; // 'warning', 'danger', 'info'
  final String title;
  final String message;
  final String location;
  final DateTime timestamp;
  final bool isActive;

  Alert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.location,
    required this.timestamp,
    required this.isActive,
  });

  Color get color {
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

  Color get backgroundColor {
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

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
  }
}