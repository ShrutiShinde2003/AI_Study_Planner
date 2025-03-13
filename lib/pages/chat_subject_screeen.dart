import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:study_planner/services/gemini_api_service.dart';
import 'package:study_planner/models/flashcard_model.dart';
import 'package:study_planner/pages/flashcard_view_page.dart';

class ChatSubjectScreen extends StatefulWidget {
  final String subject;

  ChatSubjectScreen({required this.subject});

  @override
  _ChatSubjectScreenState createState() => _ChatSubjectScreenState();
}

class _ChatSubjectScreenState extends State<ChatSubjectScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late GeminiApiService _geminiApiService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService();
  }

  ///  Send text message and AI reply
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;
    String userId = _auth.currentUser!.uid;

    await _saveMessage(userId, message, "user");

    setState(() => _isLoading = true);

    final reply = await _geminiApiService.sendMessageWithOptionalImage(
      "$message (Subject: ${widget.subject})",
    );

    await _saveMessage(userId, reply.trim(), "ai");

    setState(() => _isLoading = false);
  }

  ///  File picker & command ask
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

  /// Command input dialog
  Future<void> _askCommand(File file, {required bool isImage}) async {
    final TextEditingController _promptController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Command for ${isImage ? 'Image' : 'PDF'}"),
        content: TextField(
          controller: _promptController,
          decoration: InputDecoration(hintText: "e.g., Summarize, Generate Flashcards"),
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

  ///  Process file with AI & handle response based on command
  Future<void> _processFile(File file, String command, bool isImage) async {
    String userId = _auth.currentUser!.uid;
    setState(() => _isLoading = true);

    String response = "";
    List<Flashcard> flashcards = [];

    if (isImage) {
      response = await _geminiApiService.sendMessageWithOptionalImage(command, imageFile: file);
    } else {
      // If PDF and asking for flashcards
      if (command.toLowerCase().contains('flashcard')) {
        flashcards = await _geminiApiService.processPDF(file);
      } else {
        // Summarize/Analyze other commands
        response = await _geminiApiService.sendMessageWithOptionalPdf(command, pdfFile: file);
      }
    }

    setState(() => _isLoading = false);

    if (command.toLowerCase().contains('flashcard')) {
      // Show flashcards if generated
      if (flashcards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FlashcardViewPage(flashcards: flashcards)),
        );
      } else {
        _showSnackBar("Failed to generate flashcards.");
      }
    } else {
      // Else, show response as chat message
      await _saveMessage(userId, response.trim(), "ai");
    }
  }

  ///  Save chat message to Firestore
  Future<void> _saveMessage(String userId, String text, String sender) async {
    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": sender,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  ///  Show snack bar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  ///  Main build
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
              stream: _firestore.collection('chats').doc(userId).collection(widget.subject).orderBy('timestamp').snapshots(),
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