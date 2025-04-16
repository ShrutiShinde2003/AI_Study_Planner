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
      final atBottom = _scrollController.offset >= _scrollController.position.maxScrollExtent - 100;
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

  Future<void> _processFile(File file, String command, bool isImage) async {
    String userId = _auth.currentUser!.uid;
    setState(() => _isLoading = true);

    String response = "";
    List<Flashcard> flashcards = [];

    if (isImage) {
      response = await _geminiApiService.sendMessageWithOptionalImage(command, imageFile: file);
    } else {
      if (command.toLowerCase().contains('flashcard')) {
        flashcards = await _geminiApiService.processPDF(file);
      } else {
        response = await _geminiApiService.sendMessageWithOptionalPdf(command, pdfFile: file);
      }
    }

    setState(() => _isLoading = false);

    if (command.toLowerCase().contains('flashcard')) {
      if (flashcards.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FlashcardViewPage(flashcards: flashcards)),
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
    await _firestore.collection('chats').doc(userId).collection(widget.subject).add({
      "sender": sender,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
Widget build(BuildContext context) {
  String userId = _auth.currentUser!.uid;

  return Scaffold(
    appBar: AppBar(
      title: Text("${widget.subject} Chat"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0.5,
      centerTitle: true,
    ),
    backgroundColor: Color(0xFFF7F7F7),
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
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;
                  return ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    children: messages.map((msg) {
                      final isUser = msg['sender'] == 'user';
                      return Align(
                        alignment:
                            isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          margin: EdgeInsets.symmetric(vertical: 4),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isUser ? Colors.blueAccent : Colors.grey.shade300,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft:
                                  isUser ? Radius.circular(16) : Radius.circular(0),
                              bottomRight:
                                  isUser ? Radius.circular(0) : Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text("Processing...", style: TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        hintText: "Ask something...",
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.upload_file, color: Colors.deepPurple),
                    onPressed: uploadFileAndCommand,
                  ),
                  SizedBox(width: 4),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          sendMessage(text);
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_showScrollToBottomButton)
          Positioned(
            bottom: 90,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blueAccent,
              elevation: 4,
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
              child: Icon(Icons.arrow_downward, color: Colors.white),
            ),
          ),
      ],
    ),
  );
}
}