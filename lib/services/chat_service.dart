import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hive/hive.dart';

class ChatService {
  static late IO.Socket socket;
  static const String cacheBoxName = 'chatCache';
  static final List<Function(Map)> _messageListeners = [];

  static Future<void> initialize() async {
    await Hive.openBox(cacheBoxName);
    
    socket = IO.io('http://localhost:3000', {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Connected to chat server');
    });

    // Listen for messages
    socket.on('chatMessage', (data) {
      saveMessage(data);
      _notifyListeners(data);
    });

    socket.onDisconnect((_) {
      print('Disconnected from chat server');
    });
  }

  // Save message to local cache
  static Future<void> saveMessage(Map message) async {
    final box = Hive.box(cacheBoxName);
    List messages = box.get('messages', defaultValue: []);
    messages.add(message);
    await box.put('messages', messages);
  }

  // Get cached messages
  static List<dynamic> getCachedMessages() {
    final box = Hive.box(cacheBoxName);
    return box.get('messages', defaultValue: []);
  }

  // Send message
  static void sendMessage(String message) {
    final msg = {
      'text': message,
      'timestamp': DateTime.now().toIso8601String(),
      'sender': 'user',
    };

    // Save locally first
    saveMessage(msg);
    
    // Send via socket
    socket.emit('chatMessage', msg);

    _notifyListeners(msg);
  }

  // Listen for new messages
  static void onMessage(Function(Map) callback) {
    _messageListeners.add(callback);
  }

  static void _notifyListeners(Map message) {
    for (var listener in _messageListeners) {
      listener(message);
    }
  }

  // Clear chat history
  static Future<void> clearHistory() async {
    final box = Hive.box(cacheBoxName);
    await box.delete('messages');
  }

  // Disconnect
  static void disconnect() {
    socket.disconnect();
  }
}
