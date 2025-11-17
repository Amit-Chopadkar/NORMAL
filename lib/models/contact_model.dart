import 'package:flutter/material.dart';

class Contact {
  final String id;
  final String name;
  final String phone;
  final String? relationship;
  final bool isEmergencyContact;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.relationship,
    this.isEmergencyContact = true,
  });
}

class EmergencyService {
  final String id;
  final String name;
  final String phone;
  final String icon;
  final Color color;

  EmergencyService({
    required this.id,
    required this.name,
    required this.phone,
    required this.icon,
    required this.color,
  });
}