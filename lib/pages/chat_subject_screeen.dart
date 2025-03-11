import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_planner/services/gemini_api_service.dart';
import 'package:study_planner/models/flashcard_model.dart';
import 'package:study_planner/pages/interactive_flashcard.dart';

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

  List<Flashcard> _flashcards = [];

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService();
  }

  /// ✅ Send Text Message
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;
    String userId = _auth.currentUser!.uid;

    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": "user",
      "text": message,
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = true);

    final reply = await _geminiApiService.sendMessageWithOptionalImage(
      "$message (Subject: ${widget.subject})"
    );

    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": "ai",
      "text": reply.trim(),
      "timestamp": FieldValue.serverTimestamp(),
    });

    setState(() => _isLoading = false);
  }

  /// ✅ Unified File Picker + Command
  Future<void> uploadFileAndCommand() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: Icon(Icons.image, color: Colors.orange),
            title: Text("Pick Image"),
            onTap: () async {
              Navigator.pop(context);
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) _askCommand(File(image.path), isImage: true);
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text("Pick PDF"),
            onTap: () async {
              Navigator.pop(context);
              FilePickerResult? pdf = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
              if (pdf != null) _askCommand(File(pdf.files.single.path!), isImage: false);
            },
          ),
        ],
      ),
    );
  }

  /// ✅ Ask for Command
  Future<void> _askCommand(File file, {required bool isImage}) async {
    final TextEditingController _promptController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Enter command for ${isImage ? 'Image' : 'PDF'}"),
        content: TextField(
          controller: _promptController,
          decoration: InputDecoration(hintText: "e.g., Summarize, Generate flashcards"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final command = _promptController.text.trim();
              if (command.isNotEmpty) await _processFile(file, command, isImage);
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  /// ✅ File & Command Processing
  Future<void> _processFile(File file, String command, bool isImage) async {
    String userId = _auth.currentUser!.uid;

    setState(() {
      _isLoading = true;
      _flashcards = [];
    });

    String response;
    if (isImage) {
      response = await _geminiApiService.sendMessageWithOptionalImage(command, imageFile: file);
    } else {
      response = await _geminiApiService.sendMessageWithOptionalPdf(command, pdfFile: file);
    }

    final flashcards = _geminiApiService.extractFlashcards(response);
    if (flashcards.isNotEmpty) {
      setState(() => _flashcards = flashcards);
    } else {
      await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
        "sender": "ai",
        "text": response.trim(),
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser!.uid;

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
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: messages.map((msg) {
                    final isUser = msg['sender'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg['text']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          /// 🔹 Flashcards Section
          if (_flashcards.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text("Flashcards", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: _flashcards.length,
                controller: PageController(viewportFraction: 0.85),
                itemBuilder: (context, index) {
                  final card = _flashcards[index];
                  return InteractiveFlashcard(flashcard: card);
                },
              ),
            ),
          ],

          /// 🔹 Loading Spinner
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text("Processing...", style: TextStyle(fontSize: 16)),
              ]),
            ),

          /// 🔹 Input & Actions
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(labelText: "Ask something...", border: OutlineInputBorder()),
                  ),
                ),
                SizedBox(width: 10),
                IconButton(icon: Icon(Icons.upload_file, color: Colors.deepPurple), onPressed: uploadFileAndCommand),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      sendMessage(text);
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
