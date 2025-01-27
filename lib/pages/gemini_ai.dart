import 'package:flutter/material.dart';
import 'package:study_planner/services/gemini_api_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  String _chatbotReply = "";
  bool _isLoading = false;

  // Initialize the Gemini API service
  late GeminiApiService _geminiApiService;

  @override
  void initState() {
    super.initState();
    // Pass the API key to the service
    _geminiApiService = GeminiApiService('AIzaSyARGA2fjBuvflLE6-HOE1i9CGDuXTk8krk');
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final reply = await _geminiApiService.sendMessage(message);

    setState(() {
      _chatbotReply = reply;
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  alignment: Alignment.topLeft,
                  child: Text(
                    _chatbotReply.isNotEmpty ? _chatbotReply : "Ask something to the AI!",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ),
            ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: "Enter your message",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      final userMessage = _controller.text.trim();
                      if (userMessage.isNotEmpty) {
                        sendMessage(userMessage);
                        _controller.clear();
                      }
                    },
                    child: Text("Send"),
                  ),
          ],
        ),
      ),
    );
  }
}
