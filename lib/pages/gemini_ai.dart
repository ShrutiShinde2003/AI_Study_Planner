import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// void main() {
//   runApp(ChatApp());
// }

// class ChatApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: ChatScreen(),
//     );
//   }
// }

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController(); // Input controller
  String _chatbotReply = ""; // Stores chatbot's response
  bool _isLoading = false; // Loading indicator

  // Function to send a message to the Flask server
  Future<void> sendMessage(String message) async {
    final String flaskUrl = "http://192.168.255.84:5000/api/endpoint"; // Update with Flask server URL

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      // Send POST request to Flask server
      final response = await http.post(
        Uri.parse(flaskUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _chatbotReply = data['reply']; // Display chatbot's response
        });
      } else {
        setState(() {
          _chatbotReply = "Error: ${response.body}"; // Handle errors
        });
      }
    } catch (e) {
      setState(() {
        _chatbotReply = "Error: Unable to connect to the server."; // Handle connection errors
      });
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
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
                ? CircularProgressIndicator() // Show a loading spinner while waiting for response
                : ElevatedButton(
                    onPressed: () {
                      String userMessage = _controller.text.trim();
                      if (userMessage.isNotEmpty) {
                        sendMessage(userMessage); // Send message to Flask server
                        _controller.clear(); // Clear input field
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