import 'package:study_planner/config/api_keys.dart';  // Import API key file
import 'package:flutter/material.dart';
import 'package:study_planner/services/gemini_api_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  late GeminiApiService _geminiApiService;

  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService(ApiKeys.geminiApiKey); // Use API key from external file
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": message});
      _isLoading = true;
    });

    final reply = await _geminiApiService.sendMessage(message);

    setState(() {
      _messages.add({"sender": "ai", "text": reply});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with AI"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message["sender"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[300] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message["text"]!,
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: "Enter your message",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                _isLoading
                    ? CircularProgressIndicator()
                    : IconButton(
                        icon: Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          final userMessage = _controller.text.trim();
                          if (userMessage.isNotEmpty) {
                            sendMessage(userMessage);
                            _controller.clear();
                          }
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}