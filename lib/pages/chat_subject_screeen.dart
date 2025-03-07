import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/services/gemini_api_service.dart';
import 'package:study_planner/config/api_keys.dart';

class ChatSubjectScreen extends StatefulWidget {
  final String subject;

  ChatSubjectScreen({required this.subject});

  @override
  _ChatSubjectScreenState createState() => _ChatSubjectScreenState();
}

class _ChatSubjectScreenState extends State<ChatSubjectScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  late GeminiApiService _geminiApiService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService(ApiKeys.geminiApiKey);
  }

  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    String userId = _auth.currentUser?.uid ?? '';

    // Save user message to Firestore
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection(widget.subject)
        .add({
      "sender": "user",
      "text": message,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() {
      _isLoading = true;
    });

    // Get AI response
    final reply =
        await _geminiApiService.sendMessage("$message (Subject: ${widget.subject})");

    // Save AI response to Firestore
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection(widget.subject)
        .add({
      "sender": "ai",
      "text": reply,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} Chat")),
      body: Column(
        children: [
          // Fetch previous chats from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(userId)
                  .collection(widget.subject)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No previous messages"));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData = messages[index];
                    final isUser = messageData["sender"] == "user";

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
                          messageData["text"],
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        ),
                      ),
                    );
                  },
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

          // Message input field
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
