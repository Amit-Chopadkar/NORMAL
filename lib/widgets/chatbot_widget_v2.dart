import 'package:flutter/material.dart';
import '../services/incident_service.dart';
import '../services/chat_service.dart';

class ChatbotWidget extends StatefulWidget {
  final double userLat;
  final double userLng;

  const ChatbotWidget({Key? key, required this.userLat, required this.userLng}) : super(key: key);

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _showQuickOptions = true;

  @override
  void initState() {
    super.initState();
    _messages.add({'sender': 'bot', 'text': 'Hello! How can I help you stay safe today?'});
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _showQuickOptions = false;
    });
    _messageController.clear();

    // Send via Socket.io
    ChatService.sendMessage(text);

    // Simulate bot response based on keyword
    Future.delayed(const Duration(milliseconds: 800), () {
      String response = 'I understand. How else can I assist?';
      if (text.toLowerCase().contains('safe place')) {
        response = 'I recommend visiting Tourist Zone (0.2 km away, SAFE). Would you like more recommendations?';
      } else if (text.toLowerCase().contains('incident')) {
        response = 'You can report an incident. Tap "Report Incident" button to proceed.';
      } else if (text.toLowerCase().contains('efir')) {
        response = 'I can help generate an e-FIR for missing persons. Tap "Generate e-FIR" to start.';
      }

      if (mounted) {
        setState(() {
          _messages.add({'sender': 'bot', 'text': response});
        });
      }
    });
  }

  Future<void> _generateEFIR() async {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtrl = TextEditingController();
        final descCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Generate e-FIR'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Person Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final efirId = await IncidentService.generateEFIR(
                  personName: nameCtrl.text,
                  lastKnownLocation: 'Lat: ${widget.userLat}, Lng: ${widget.userLng}',
                  description: descCtrl.text,
                  latitude: widget.userLat,
                  longitude: widget.userLng,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _messages.add({'sender': 'bot', 'text': 'e-FIR Generated: $efirId'});
                  });
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  void _reportIncident() {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Report Incident'),
          content: TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Incident Title'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await IncidentService.reportIncident(
                  title: titleCtrl.text,
                  description: 'Live incident report',
                  category: 'Suspicious Activity',
                  latitude: widget.userLat,
                  longitude: widget.userLng,
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _messages.add({'sender': 'bot', 'text': 'Incident reported to authorities!'});
                  });
                }
              },
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, idx) {
              final msg = _messages[idx];
              final isBot = msg['sender'] == 'bot';
              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.grey[200] : Colors.blue[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(msg['text'] ?? ''),
                ),
              );
            },
          ),
        ),
        if (_showQuickOptions)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              children: [
                ElevatedButton.icon(
                  onPressed: _generateEFIR,
                  icon: const Icon(Icons.description),
                  label: const Text('Generate e-FIR'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _reportIncident,
                  icon: const Icon(Icons.report),
                  label: const Text('Report Incident'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Type message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _sendMessage(_messageController.text),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
