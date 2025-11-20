import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class EmergencyService {
  static final List<Map<String, dynamic>> _emergencyContacts = [
    {
      'name': 'Police',
      'phone': '100',
      'icon': '🚓',
      'color': 'blue',
    },
    {
      'name': 'Ambulance',
      'phone': '102',
      'icon': '🚑',
      'color': 'green',
    },
    {
      'name': 'Fire Brigade',
      'phone': '101',
      'icon': '🚒',
      'color': 'orange',
    },
    {
      'name': 'Tourist Helpline',
      'phone': '1363',
      'icon': 'ℹ️',
      'color': 'grey',
    },
  ];

  static Future<void> makeEmergencyCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  static Future<void> triggerSOS({
    required String currentLocation,
    required List<Map<String, dynamic>> emergencyContacts,
  }) async {
    // 1. Play siren sound
    final audioPlayer = AudioPlayer();
    await audioPlayer.play(AssetSource('sounds/siren.mp3'));

    // 2. Send location to emergency contacts (simulated)
    for (final contact in emergencyContacts) {
      // In real app, send SMS with location
      final name = contact['name'] ?? 'Contact';
      final phone = contact['phone'] ?? 'unknown';
      print('Alerting $name at $phone');
      print('Emergency at: $currentLocation');
    }

    // 3. Notify local authorities (simulated)
    print('Notifying police and emergency services');
    print('Location: $currentLocation');

    // Stop siren after 10 seconds
    Future.delayed(const Duration(seconds: 10), () async {
      await audioPlayer.stop();
    });
  }

  static List<Map<String, dynamic>> getEmergencyContacts() {
    return _emergencyContacts;
  }

  static Future<void> shareLocation(String message) async {
    final url = 'https://maps.google.com/?q=20.0112,73.7909';
    final fullMessage = '$message\nLocation: $url';
    
    final uri = Uri(
      scheme: 'sms',
      queryParameters: {'body': fullMessage},
    );
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch SMS';
    }
  }
}