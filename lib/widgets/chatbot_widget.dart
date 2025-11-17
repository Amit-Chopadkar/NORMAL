import 'package:flutter/material.dart';
import '../models/suggestion_model.dart';

class ChatbotWidget extends StatefulWidget {
  final VoidCallback onClose;

  const ChatbotWidget({super.key, required this.onClose});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Suggestion> _suggestions = [
    Suggestion(id: '1', text: 'Report an incident', type: 'emergency'),
    Suggestion(id: '2', text: 'How to file an E-FIR?', type: 'info'),
    Suggestion(id: '3', text: 'Give me safety tips', type: 'info'),
    Suggestion(id: '4', text: 'Nearby facilities', type: 'location'),
  ];

  @override
  void initState() {
    super.initState();
    _addBotMessage('Hello! I\'m your AI safety assistant. How can I help you today?');
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _handleSendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _addUserMessage(text);
    _textController.clear();
    _getBotResponse(text);
  }

  void _handleSuggestionTap(String text) {
    _addUserMessage(text);
    _getBotResponse(text);
  }

  void _getBotResponse(String userMessage) {
    // Simulate bot thinking
    Future.delayed(const Duration(seconds: 1), () {
      String response = "I'm a demo assistant. For real-time help, please contact local authorities via the Emergency page.";
      
      if (userMessage.toLowerCase().contains("incident")) {
        response = "To report an incident, please describe what happened. If this is an emergency, please use the Emergency page.";
      } else if (userMessage.toLowerCase().contains("fir")) {
        response = "You can file an E-FIR through the official state police portal. I can provide the link if you need it.";
      } else if (userMessage.toLowerCase().contains("safety") || userMessage.toLowerCase().contains("tips")) {
        response = "Safety tips for Nashik: 1. Be aware of your surroundings. 2. Avoid unlit areas at night. 3. Keep valuables secure. 4. Use trusted transportation. 5. Save emergency contacts.";
      } else if (userMessage.toLowerCase().contains("nearby") || userMessage.toLowerCase().contains("facilities")) {
        response = "Nearby safe facilities include the Central Bus Stand and the main Police Station. You can find more places on the Explore page.";
      } else if (userMessage.toLowerCase().contains("emergency")) {
        response = "For emergencies, please use the SOS button on the Emergency page. It will immediately notify authorities and your emergency contacts.";
      }

      _addBotMessage(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Container(
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[800],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'Safety Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return ChatBubble(message: message);
                },
              ),
            ),

            // Suggestions
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => _handleSuggestionTap(suggestion.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue[800],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.blue[200]!),
                        ),
                      ),
                      child: Text(suggestion.text),
                    ),
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue[800],
                    child: IconButton(
                      onPressed: _handleSendMessage,
                      icon: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[600] : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.grey[800],
                ),
              ),
            ),
          ),
          if (message.isUser)
            const SizedBox(width: 8),
          if (message.isUser)
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=rajeshkumar'),
            ),
        ],
      ),
    );
  }
}