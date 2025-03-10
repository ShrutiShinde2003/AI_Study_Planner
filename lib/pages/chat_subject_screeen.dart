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

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService(); // Initialize Gemini service
  }

  /// ✅ Clean AI Response
  String cleanText(String text) => text.replaceAll('*', '').trim();

  /// ✅ Send Text Message
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    String userId = _auth.currentUser?.uid ?? '';

    // Save user message
    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": "user",
      "text": message,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = true);

    // AI response
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

  /// ✅ Unified File Picker (Image or PDF) + Command Prompt
  Future<void> uploadFileAndGiveCommand() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.image, color: Colors.orange),
            title: Text("Pick Image"),
            onTap: () async {
              Navigator.pop(context);
              final ImagePicker picker = ImagePicker();
              final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                File imageFile = File(pickedFile.path);
                _askCommandForFile(imageFile, isImage: true);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text("Pick PDF"),
            onTap: () async {
              Navigator.pop(context);
              FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
              if (result != null) {
                File pdfFile = File(result.files.single.path!);
                _askCommandForFile(pdfFile, isImage: false);
              }
            },
          ),
        ],
      ),
    );
  }

  /// ✅ Ask command (prompt) for selected file (Image or PDF)
  Future<void> _askCommandForFile(File file, {required bool isImage}) async {
    final TextEditingController _promptController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Give command for ${isImage ? 'Image' : 'PDF'}"),
        content: TextField(
          controller: _promptController,
          decoration: InputDecoration(hintText: "Example: Summarize this file or Generate flashcards"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final command = _promptController.text.trim();
              if (command.isNotEmpty) {
                await _processFileWithCommand(file, command, isImage: isImage);
              }
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  /// ✅ Handle File + Command and generate AI response
  Future<void> _processFileWithCommand(File file, String command, {required bool isImage}) async {
    String userId = _auth.currentUser?.uid ?? '';

    setState(() => _isLoading = true);

    // Unified processing
    String aiResponse;
    if (isImage) {
      aiResponse = await _geminiApiService.sendMessageWithOptionalImage(command, imageFile: file);
    } else {
      aiResponse = await _geminiApiService.sendMessageWithOptionalPdf(command, pdfFile: file);
    }

    String cleanedResponse = cleanText(aiResponse);

    // Save AI response
    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": "ai",
      "text": cleanedResponse,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} Chat")),
      body: Column(
        children: [
          /// 🔹 Chat Messages
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
                        child: Text(messageData["text"], style: TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                );
              },
            ),
          ),

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

          /// 🔹 Input Field + Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: "Enter your message", border: OutlineInputBorder()),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.upload_file, color: Colors.deepPurple, size: 28),
                  onPressed: uploadFileAndGiveCommand, // ✅ Single button for both
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
