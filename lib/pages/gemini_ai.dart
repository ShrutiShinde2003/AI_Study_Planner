import 'package:study_planner/config/api_keys.dart'; // Import API key file
import 'package:flutter/material.dart';
import 'package:study_planner/services/gemini_api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
    _geminiApiService = GeminiApiService(ApiKeys.geminiApiKey);
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

  Future<void> uploadAndProcessPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() {
        _messages.add({
          "sender": "user",
          "text": "📄 Uploaded a PDF: ${result.files.single.name}"
        });
        _isLoading = true;
      });

      String summary = await _geminiApiService.processPDF(file);

      setState(() {
        _messages.add({"sender": "ai", "text": "📚 Flashcards:\n$summary"});
        _isLoading = false;
      });
    }
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
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
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
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 10),
                  Text("Processing...", style: TextStyle(fontSize: 16)),
                ],
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
                IconButton(
                  icon: Icon(Icons.upload_file, color: Colors.green, size: 28),
                  onPressed: uploadAndProcessPDF,
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue, size: 28),
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
