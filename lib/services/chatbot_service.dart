import 'package:hive/hive.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class ChatbotService {
  static const String boxName = 'chatbotBox';
  static List<ChatMessage> _messages = [];
  static final List<Function(ChatMessage)> _listeners = [];

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    await _loadMessages();
  }

  static Future<void> _loadMessages() async {
    try {
      final box = Hive.box(boxName);
      final saved = box.get('messages', defaultValue: []) as List<dynamic>;
      _messages = saved.map((m) => ChatMessage.fromMap(m as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  static List<ChatMessage> getMessages() => _messages;

  static Future<void> sendMessage(String text) async {
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    _notifyListeners(msg);
    await _saveMessages();

    // Simulate bot response after 1 second
    await Future.delayed(const Duration(seconds: 1));
    final botResponse = _getBotResponse(text);
    final botMsg = ChatMessage(
      id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
      text: botResponse,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(botMsg);
    _notifyListeners(botMsg);
    await _saveMessages();
  }

  static String _getBotResponse(String userText) {
    final lower = userText.toLowerCase();

    if (lower.contains('e-fir') || lower.contains('fir')) {
      return '📋 I can help you generate an E-FIR (Electronic First Information Report). Tap "Generate E-FIR" to provide details about the missing person.';
    }

    if (lower.contains('incident') || lower.contains('report')) {
      return '🚨 I can help you report an incident. Tap "Report Incident" to submit details with your location. This will alert local authorities.';
    }

    if (lower.contains('sos') || lower.contains('emergency') || lower.contains('help')) {
      return '🆘 SOS mode is critical. Your location will be shared with emergency services. Are you in immediate danger? Tap "Emergency SOS" to activate.';
    }

    if (lower.contains('location') || lower.contains('share')) {
      return '📍 I can help you share your location with family. Go to Settings → Family Tracking → Share Location with Family to enable real-time sharing.';
    }

    if (lower.contains('family') || lower.contains('tracking')) {
      return '👨‍👩‍👧‍👦 Family Tracking lets you share your location with trusted contacts. Enable it in Settings to send periodic location updates via a secure connection.';
    }

    if (lower.contains('zone') || lower.contains('safe') || lower.contains('danger')) {
      return '🛡️ You can see nearby zones and their safety levels on the Dashboard. Red = Danger, Orange = Caution, Green = Safe. Stay informed!';
    }

    if (lower.contains('alert') || lower.contains('warning')) {
      return '⚠️ Active alerts show real-time warnings about your area. Check the Dashboard for current alerts and zone updates.';
    }

    if (lower.contains('contact') || lower.contains('emergency')) {
      return '☎️ Your emergency contacts are in Settings. You can add trusted people there. They will receive alerts if you report an incident.';
    }

    if (lower.contains('language') || lower.contains('hindi') || lower.contains('spanish')) {
      return '🌍 The app supports multiple languages: English, Hindi, and Spanish. Change your language in Settings → Language & Region.';
    }

    if (lower.contains('offline') || lower.contains('internet')) {
      return '📱 The app works offline! Your reports and location are cached locally. They sync to the server when you regain connectivity.';
    }

    // Default response
    return 'Hi! I\'m your safety assistant. I can help you with:\n• Reporting incidents\n• Generating E-FIRs\n• Emergency SOS\n• Family tracking\n• Zone safety info\n\nWhat do you need help with?';
  }

  static void onMessage(Function(ChatMessage) callback) {
    _listeners.add(callback);
  }

  static void _notifyListeners(ChatMessage message) {
    for (var listener in _listeners) {
      listener(message);
    }
  }

  static Future<void> _saveMessages() async {
    try {
      final box = Hive.box(boxName);
      await box.put('messages', _messages.map((m) => m.toMap()).toList());
    } catch (e) {
      print('Error saving messages: $e');
    }
  }

  static Future<void> clearMessages() async {
    _messages.clear();
    final box = Hive.box(boxName);
    await box.delete('messages');
  }

  static List<String> getSuggestions() {
    return [
      '🚨 Report Incident',
      '📋 Generate E-FIR',
      '🆘 Emergency SOS',
      '📍 Share Location',
      '👨‍👩‍👧‍👦 Family Tracking',
      '🛡️ Zone Safety',
      '☎️ Emergency Contacts',
      '🌍 Languages',
    ];
  }
}
