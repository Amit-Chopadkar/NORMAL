import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../services/family_tracking_service.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';
import '../widgets/setting_tile.dart';
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

  late String _selectedLanguage;
  bool _showLanguageOptions = false;

  List<Contact> _emergencyContacts = [];
  bool _showContactModal = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocalizationService.getCurrentLanguage();
    _loadSavedContacts();
  }

  Future<void> _loadSavedContacts() async {
    try {
      final box = await Hive.openBox('userBox');
      final saved = box.get('emergencyContacts', defaultValue: []) as List<dynamic>;
      setState(() {
        _emergencyContacts = saved.map((e) {
          if (e is Map) {
            return Contact(id: e['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), name: e['name'] ?? '', phone: e['phone'] ?? '');
          }
          return Contact(id: DateTime.now().millisecondsSinceEpoch.toString(), name: e.toString(), phone: e.toString());
        }).toList();
      });
    } catch (e) {
      // ignore
    }
  }

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
      // persist
      final box = Hive.box('userBox');
      final list = _emergencyContacts.map((c) => {'id': c.id, 'name': c.name, 'phone': c.phone}).toList();
      box.put('emergencyContacts', list);
      _nameController.clear();
      _phoneController.clear();
      _showContactModal = false;
    }
  }

  void _removeEmergencyContact(String id) {
    setState(() {
      _emergencyContacts.removeWhere((contact) => contact.id == id);
    });
    final box = Hive.box('userBox');
    final list = _emergencyContacts.map((c) => {'id': c.id, 'name': c.name, 'phone': c.phone}).toList();
    box.put('emergencyContacts', list);
  }

  Future<void> _handleFamilyTrackingToggle(bool value) async {
    if (!value) {
      setState(() {
        _familyTracking = false;
        _shareLocation = false;
      });
      await FamilyTrackingService.stop();
      return;
    }

    setState(() => _familyTracking = true);

    if (_emergencyContacts.isEmpty) {
      setState(() => _showContactModal = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an emergency contact to share updates with your family')),
      );
      return;
    }

    if (_shareLocation) {
      await FamilyTrackingService.start();
      await _sendCurrentLocationToFamily();
    }
  }

  Future<void> _sendCurrentLocationToFamily() async {
    final phoneNumbers = _emergencyContacts
        .map((c) => c.phone.trim())
        .where((phone) => phone.isNotEmpty)
        .join(',');

    if (phoneNumbers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid phone numbers found for your family contacts')),
      );
      return;
    }

    try {
      final position = await LocationService.getCurrentLocation();
      final lat = position.latitude;
      final lng = position.longitude;
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      final message =
          'Family Tracking enabled.\nCurrent location: $mapsUrl\nCoordinates: $lat, $lng\nTime: ${DateTime.now().toLocal()}';
      final smsUri = Uri.parse('sms:$phoneNumbers?body=${Uri.encodeComponent(message)}');
      final launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Could not open the SMS app');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared your current location with family contacts')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to share location: $e')),
      );
    }
  }

  Future<bool> _ensureFamilyContactsAvailable() async {
    if (_emergencyContacts.isNotEmpty) {
      return true;
    }
    setState(() => _showContactModal = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add at least one emergency contact to share your location')),
    );
    return false;
  }

  Future<void> _changeLanguage(String languageCode) async {
    await LocalizationService.setLanguage(languageCode);
    setState(() {
      _selectedLanguage = languageCode;
      _showLanguageOptions = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Language changed to ${LocalizationService.getLanguageName(languageCode)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: <Widget>[
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24), // Top padding
                // Header
                Text(
                  tr('settings'),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Safety & Monitoring
                _buildSectionHeader('safety_monitoring'),
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
                        title: tr('location_tracking'),
                        value: _locationTracking,
                        onChanged: (value) =>
                            setState(() => _locationTracking = value),
                      ),
                      SettingTile(
                        icon: Icons.notifications,
                        iconColor: Colors.red,
                        title: tr('notifications'),
                        value: _emergencyAlerts,
                        onChanged: (value) =>
                            setState(() => _emergencyAlerts = value),
                      ),
                      SettingTile(
                        icon: Icons.shield,
                        iconColor: Colors.orange,
                        title: 'Geofence Alerts',
                        value: _geofenceAlerts,
                        onChanged: (value) =>
                            setState(() => _geofenceAlerts = value),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Incident Reporting
                _buildSectionHeader('incident_tracking'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListTile(
                    leading: Icon(Icons.report_problem, color: Colors.red[700]),
                    title: Text(
                      tr('my_incident_reports'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(tr('view_and_track_reports')),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyIncidentsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Family & Contacts
                _buildSectionHeader('family_contacts'),
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
                        title: tr('family_tracking'),
                        value: _familyTracking,
                        onChanged: (value) => _handleFamilyTrackingToggle(value),
                      ),
                      ListTile(
                        leading: Icon(Icons.phone, color: Colors.grey[600]),
                        title: Text(
                          tr('emergency_contacts'),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: IconButton(
                          onPressed: _familyTracking
                              ? () => setState(() => _showContactModal = true)
                              : null,
                          icon: Icon(Icons.add_circle,
                              color: _familyTracking
                                  ? Colors.green
                                  : Colors.grey),
                        ),
                        enabled: _familyTracking,
                      ),
                      if (_emergencyContacts.isNotEmpty)
                        ..._buildContactList(),
                      SettingTile(
                        icon: Icons.share,
                        iconColor: Colors.purple,
                        title: tr('share_location_family'),
                        value: _shareLocation,
                        onChanged: (value) async {
                          if (value) {
                            if (!_familyTracking) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enable Family Tracking first')),
                              );
                              return;
                            }
                            final hasContacts = await _ensureFamilyContactsAvailable();
                            if (!hasContacts) {
                              return;
                            }
                            setState(() => _shareLocation = true);
                            await FamilyTrackingService.start();
                            await _sendCurrentLocationToFamily();
                          } else {
                            setState(() => _shareLocation = false);
                            await FamilyTrackingService.stop();
                          }
                        },
                        enabled: _familyTracking,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Language & Region
                _buildSectionHeader('language_region'),
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
                        title: Text(
                          tr('language'),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              LocalizationService.getLanguageName(
                                  _selectedLanguage),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            Icon(
                              _showLanguageOptions
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        onTap: () => setState(
                            () => _showLanguageOptions = !_showLanguageOptions),
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
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(tr('logout')),
                            content: Text(tr('logout_confirm_message')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(tr('cancel')),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text(tr('logged_out_successfully')),
                                    ),
                                  );
                                },
                                child: Text(
                                  tr('logout'),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text(
                      tr('logout'),
                      style: const TextStyle(
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

  Widget _buildSectionHeader(String titleKey) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        tr(titleKey),
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
    return LocalizationService.getAvailableLanguages().map((code) {
      return RadioListTile<String>(
        title: Text(LocalizationService.getLanguageName(code)),
        value: code,
        groupValue: _selectedLanguage,
        onChanged: (value) {
          if (value != null) {
            _changeLanguage(value);
          }
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
                      onPressed: () =>
                          setState(() => _showContactModal = false),
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
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
