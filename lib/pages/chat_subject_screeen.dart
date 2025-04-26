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
  final ScrollController _scrollController = ScrollController();
  late GeminiApiService _geminiApiService;
  bool _isLoading = false;
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _geminiApiService = GeminiApiService();

    _scrollController.addListener(() {
      final atBottom = _scrollController.offset >=
          _scrollController.position.maxScrollExtent - 100;
      if (atBottom && _showScrollToBottomButton) {
        setState(() => _showScrollToBottomButton = false);
      } else if (!atBottom && !_showScrollToBottomButton) {
        setState(() => _showScrollToBottomButton = true);
      }
    });
  }

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
              final XFile? image =
                  await picker.pickImage(source: ImageSource.gallery);
              if (image != null) _askCommand(File(image.path), isImage: true);
            },
          ),
          ListTile(
            leading: Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text("Pick PDF"),
            onTap: () async {
              Navigator.pop(context);
              FilePickerResult? pdf = await FilePicker.platform
                  .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
              if (pdf != null)
                _askCommand(File(pdf.files.single.path!), isImage: false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _askCommand(File file, {required bool isImage}) async {
    final TextEditingController _promptController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Command for ${isImage ? 'Image' : 'PDF'}"),
        content: TextField(
          controller: _promptController,
          decoration:
              InputDecoration(hintText: "e.g., Summarize, Generate Flashcards"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final command = _promptController.text.trim();
              if (command.isNotEmpty)
                await _processFile(file, command, isImage);
            },
            child: Text("Submit"),
          ),
        ],
      ),
    );
  }

  Future<void> _processFile(File file, String command, bool isImage) async {
    String userId = _auth.currentUser!.uid;
    setState(() => _isLoading = true);

    String response = "";
    List<Flashcard> flashcards = [];

    if (isImage) {
      response = await _geminiApiService.sendMessageWithOptionalImage(command,
          imageFile: file);
    } else {
      if (command.toLowerCase().contains('flashcard')) {
        flashcards = await _geminiApiService.processPDF(file);
      } else {
        response = await _geminiApiService.sendMessageWithOptionalPdf(command,
            pdfFile: file);
      }
    }

    setState(() => _isLoading = false);

    if (command.toLowerCase().contains('flashcard')) {
      if (flashcards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => FlashcardViewPage(flashcards: flashcards)),
        );
      } else {
        _showSnackBar("Failed to generate flashcards.");
      }
    } else {
      await _saveMessage(userId, response.trim(), "ai");
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveMessage(String userId, String text, String sender) async {
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection(widget.subject)
        .add({
      "sender": sender,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("${widget.subject} Chat")),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('chats')
                      .doc(userId)
                      .collection(widget.subject)
                      .orderBy('timestamp')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return Center(child: CircularProgressIndicator());

                    final messages = snapshot.data!.docs;
                    return ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: messages.map((msg) {
                        final isUser = msg['sender'] == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            padding: EdgeInsets.all(12),
                            margin: EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  isUser ? Colors.blue[200] : Colors.grey[300],
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
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 10),
                        Text("Processing...", style: TextStyle(fontSize: 16)),
                      ]),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: "Ask something...",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.upload_file, color: Colors.deepPurple),
                      onPressed: uploadFileAndCommand,
                    ),
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
          if (_showScrollToBottomButton)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4)
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_downward,
                        color: Colors.white, size: 20),
                    onPressed: () {
                      _scrollController.animateTo(
                        _scrollController.position.maxScrollExtent,
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
