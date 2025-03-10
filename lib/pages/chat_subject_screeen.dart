import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_planner/services/gemini_api_service.dart';

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

  List<Map<String, String>> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService(); // ✅ Initialize service
  }

  /// ✅ Clean AI Response
  String cleanText(String text) => text.replaceAll('*', '').trim();

  /// ✅ Send Text Message using Gemini AI
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    String userId = _auth.currentUser?.uid ?? '';

    // Save user's message
    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": "user",
      "text": message,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = true);

    // 🔑 Using unified function for AI response
    final reply = await _geminiApiService.sendMessageWithOptionalImage(
      "$message (Subject: ${widget.subject})"
    );
    String cleanedReply = cleanText(reply);

    // Save AI response
    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": "ai",
      "text": cleanedReply,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);
  }

  /// ✅ Upload and Process PDF to Flashcards
  Future<void> uploadAndProcessPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) {
      File file = File(result.files.single.path!);
      String userId = _auth.currentUser?.uid ?? '';

      setState(() {
        _isLoading = true;
        _flashcards = [];
      });

      List<Map<String, String>> flashcards = await _geminiApiService.processPDF(file);
      setState(() {
        _isLoading = false;
        _flashcards = flashcards.isNotEmpty ? flashcards : [{"question": "Error", "answer": "No flashcards generated."}];
      });

      // Save each flashcard as AI response
      for (var flashcard in flashcards) {
        await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
          "sender": "ai",
          "text": "Q: ${cleanText(flashcard['question']!)}\nA: ${cleanText(flashcard['answer']!)}",
          "timestamp": FieldValue.serverTimestamp(),
        });
      }
    }
  }

  /// ✅ Upload and Process Image using Gemini
  Future<void> uploadAndProcessImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String userId = _auth.currentUser?.uid ?? '';

      setState(() => _isLoading = true);

      // 🔑 Using unified function for AI response
      String aiResponse = await _geminiApiService.sendMessageWithOptionalImage(
        "Please analyze this image and answer relevant questions related to ${widget.subject}",
        imageFile: imageFile,
      );
      String cleanedResponse = cleanText(aiResponse);

      // Save AI response
      await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
        "sender": "ai",
        "text": cleanedResponse,
        "timestamp": FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} Chat")),
      body: Column(
        children: [
          /// 🔹 Display Chat Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(userId)
                  .collection(widget.subject)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No previous messages"));

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

          /// 🔹 Flashcards Section
          if (_flashcards.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("Generated Flashcards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._flashcards.map((flashcard) => Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Q: ${cleanText(flashcard['question']!)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                        const SizedBox(height: 8),
                        Text("A: ${cleanText(flashcard['answer']!)}", style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                )),
          ],

          /// 🔹 Loading Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text("Processing...", style: TextStyle(fontSize: 16)),
              ]),
            ),

          /// 🔹 Input Field and Actions
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
                IconButton(
                  icon: Icon(Icons.image, color: Colors.orange, size: 28),
                  onPressed: uploadAndProcessImage, // ✅ Image Upload
                ),
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
