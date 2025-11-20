import 'package:flutter/material.dart';
import '../services/localization_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LocalizationService.languageNotifier,
      builder: (context, language, _) {
        return _buildProfile();
      },
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('profile')),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Avatar
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: const Text('RK', style: TextStyle(fontSize: 32)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Rajesh Kumar',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'ID: TID-2025-001234',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Profile Info Cards
              _buildInfoCard(tr('email'), 'rajesh@example.com'),
              const SizedBox(height: 12),
              _buildInfoCard(tr('phone'), '+91 98765 43210'),
              const SizedBox(height: 12),
              _buildInfoCard(tr('country'), 'India'),
              const SizedBox(height: 12),
              _buildInfoCard(tr('member_since'), 'January 2025'),
              const SizedBox(height: 24),
              // Emergency Contacts
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('emergency_contacts'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem('Mother', '+91 98765 43211'),
                    const SizedBox(height: 8),
                    _buildContactItem('Father', '+91 98765 43212'),
                    const SizedBox(height: 8),
                    _buildContactItem('Sister', '+91 98765 43213'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, String phone) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name),
        Text(phone, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
