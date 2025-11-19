import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ChatbotWidget extends StatefulWidget {
  final VoidCallback onClose;

  const ChatbotWidget({super.key, required this.onClose});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initializeChatbot();
  }

  void _initializeChatbot() async {
    await ChatbotService.initialize();

    // Load previous messages
    _messages = ChatbotService.getMessages();
    _suggestions = ChatbotService.getSuggestions();

    // If no previous messages, add greeting
    if (_messages.isEmpty) {
      await ChatbotService.sendMessage('');
    }

    // Listen to messages
    ChatbotService.onMessage((message) {
      if (mounted) {
        setState(() {
          _messages = ChatbotService.getMessages();
        });
        _scrollToBottom();
      }
    });

    setState(() {
      _messages = _messages;
      _suggestions = _suggestions;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await ChatbotService.sendMessage(text);
    setState(() {
      _messages = ChatbotService.getMessages();
    });
  }

  void _handleSuggestionTap(String text) async {
    await ChatbotService.sendMessage(text);
    setState(() {
      _messages = ChatbotService.getMessages();
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
              child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'Loading...',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  : ListView.builder(
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
            if (_suggestions.isNotEmpty)
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
                        onPressed: () => _handleSuggestionTap(suggestion),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[800],
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.blue[200]!),
                          ),
                        ),
                        child: Text(suggestion),
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
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
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }
}