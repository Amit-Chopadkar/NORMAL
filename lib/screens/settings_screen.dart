import 'package:flutter/material.dart';
import '../models/contact_model.dart';
import '../widgets/setting_tile.dart';
import '../services/localization_service.dart';
import 'my_incidents_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationTracking = true;
  bool _emergencyAlerts = true;
  bool _geofenceAlerts = true;
  bool _familyTracking = false;
  bool _shareLocation = false;
  
  String _selectedLanguage = 'English';
  bool _showLanguageOptions = false;
  
  List<Contact> _emergencyContacts = [];
  bool _showContactModal = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final List<String> _languages = [
    'English',
    'Hindi (हिन्दी)',
    'Punjabi (ਪੰਜਾਬੀ)',
    'Gujarati (ગુજરાતી)',
    'Kannada (ಕನ್ನಡ)',
    'Bengali (বাংলা)',
    'Malayalam (മലയാളം)',
    'Urdu (اردو)',
    'Bhojpuri (भोजपुरी)',
    'Telugu (తెలుగు)',
  ];

  void _addEmergencyContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    
    if (name.isNotEmpty && phone.isNotEmpty) {
      setState(() {
        _emergencyContacts.add(Contact(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          phone: phone,
        ));
      });
      _nameController.clear();
      _phoneController.clear();
      _showContactModal = false;
    }
  }

  void _removeEmergencyContact(String id) {
    setState(() {
      _emergencyContacts.removeWhere((contact) => contact.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Safety & Monitoring
                _buildSectionHeader('Safety & Monitoring'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.location_on,
                        iconColor: Colors.green,
                        title: 'Location Tracking',
                        value: _locationTracking,
                        onChanged: (value) => setState(() => _locationTracking = value),
                      ),
                      SettingTile(
                        icon: Icons.notifications,
                        iconColor: Colors.red,
                        title: 'Emergency Alerts',
                        value: _emergencyAlerts,
                        onChanged: (value) => setState(() => _emergencyAlerts = value),
                      ),
                      SettingTile(
                        icon: Icons.shield,
                        iconColor: Colors.orange,
                        title: 'Geofence Alerts',
                        value: _geofenceAlerts,
                        onChanged: (value) => setState(() => _geofenceAlerts = value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Family & Contacts
                _buildSectionHeader('Family & Contacts'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      SettingTile(
                        icon: Icons.person,
                        iconColor: Colors.blue,
                        title: 'Family Tracking',
                        value: _familyTracking,
                        onChanged: (value) => setState(() => _familyTracking = value),
                      ),
                      ListTile(
                        leading: Icon(Icons.phone, color: Colors.grey[600]),
                        title: const Text(
                          'Emergency Contacts',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          onPressed: _familyTracking ? () => setState(() => _showContactModal = true) : null,
                          icon: Icon(Icons.add_circle, color: _familyTracking ? Colors.green : Colors.grey),
                        ),
                        enabled: _familyTracking,
                      ),
                      if (_emergencyContacts.isNotEmpty) ..._buildContactList(),
                      SettingTile(
                        icon: Icons.share,
                        iconColor: Colors.purple,
                        title: 'Share Location with Family',
                        value: _shareLocation,
                        onChanged: _familyTracking ? (value) { setState(() => _shareLocation = value); } : null,
                        enabled: _familyTracking,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Language & Region
                _buildSectionHeader('Language & Region'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.language, color: Colors.green),
                        title: const Text(
                          'Language',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedLanguage,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Icon(
                              _showLanguageOptions ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        onTap: () => setState(() => _showLanguageOptions = !_showLanguageOptions),
                      ),
                      if (_showLanguageOptions) ..._buildLanguageOptions(),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Logout
                Center(
                  child: TextButton(
                    onPressed: () {
                      // Handle logout
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // Contact Modal
          if (_showContactModal) _buildContactModal(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 1,
        ),
      ),
    );
  }

  List<Widget> _buildContactList() {
    return _emergencyContacts.map((contact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${contact.name} - ${contact.phone}'),
            ),
            IconButton(
              onPressed: () => _removeEmergencyContact(contact.id),
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildLanguageOptions() {
    return _languages.map((language) {
      return RadioListTile(
        title: Text(language),
        value: language,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          setState(() {
            _selectedLanguage = value!;
            _showLanguageOptions = false;
          });
        },
      );
    }).toList();
  }

  Widget _buildContactModal() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Emergency Contact',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _showContactModal = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addEmergencyContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}