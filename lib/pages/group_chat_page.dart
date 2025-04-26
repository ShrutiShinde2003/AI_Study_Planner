import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service(groups).dart';
import '../models/message_model.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage(
      {required this.groupId, required this.groupName, Key? key})
      : super(key: key);

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseGroupService _groupService = FirebaseGroupService();
  final TextEditingController _messageController = TextEditingController();

  /// ✅ Upload File to *Amazon S3*
  Future<String?> uploadFileToS3(File file) async {
    try {
      String uniqueFileName =
          "group_chats/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final uploadResult = await Amplify.Storage.uploadFile(
        local: file,
        key: uniqueFileName,
      ).result;

      final fileUrl =
          await Amplify.Storage.getUrl(key: uploadResult.key).result;
      print("✅ File uploaded to S3: $fileUrl");
      return fileUrl; // 🔹 Return file URL for Firestore
    } catch (e) {
      print("❌ Error uploading to S3: $e");
      return null;
    }
  }

  /// ✅ Send Text Message
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _groupService.sendMessage(
        widget.groupId, _messageController.text.trim(),
        fileUrl: "");
    _messageController.clear();
    FocusScope.of(context).unfocus(); // Dismiss keyboard after sending
  }

  /// ✅ Upload and Send File (Image or PDF)
  Future<void> _sendFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      String fileExtension = fileName.split('.').last;

      // ✅ Upload file to S3 instead of Firebase
      String? downloadUrl = await uploadFileToS3(file);

      if (downloadUrl != null) {
        // ✅ Send message with S3 file link
        await _groupService.sendMessage(
          widget.groupId,
          fileExtension == "pdf" ? "📄 PDF File: $fileName" : "🖼 Image",
          fileUrl: downloadUrl,
        );
      }
    }
  }

  /// ✅ Show Group Members
  void _showGroupMembers() async {
    List<Map<String, dynamic>> members =
        await _groupService.getGroupMembers(widget.groupId);

    showModalBottomSheet(
      context: context,
      builder: (context) => members.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("No members found.")),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: members.map((userData) {
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(userData['userName'] ?? 'Unknown User'),
                  subtitle: Text(userData['email'] ?? ''),
                );
              }).toList(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
              icon: const Icon(Icons.people), onPressed: _showGroupMembers),
          IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _sendFile), // 📎 Attach File Button
        ],
      ),
      body: Column(
        children: [
          /// Chat Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _groupService.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text("Something went wrong. Please try again."));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No messages yet. Start chatting!"));
                }

                var messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message.senderId == _auth.currentUser?.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message
                                  .senderName, // Sender's username above message
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54),
                            ),
                            const SizedBox(height: 3),

                            // ✅ Display File Message (Image or PDF)
                            if (message.fileUrl.isNotEmpty)
                              message.fileUrl.endsWith(".pdf")
                                  ? _buildPdfMessage(
                                      message.fileUrl) // 📄 PDF Preview
                                  : _buildImageMessage(
                                      message.fileUrl), // 🖼 Image Preview

                            // ✅ Display Text Message
                            if (message.text.isNotEmpty)
                              Text(message.text,
                                  style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// ✅ Message Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: "Enter message...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                  backgroundColor: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🖼 *Display Image Message*
  Widget _buildImageMessage(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: GestureDetector(
        onTap: () => _openFile(imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(imageUrl,
              width: 200, height: 200, fit: BoxFit.cover),
        ),
      ),
    );
  }

  /// 📄 *Display PDF Message*
  Widget _buildPdfMessage(String pdfUrl) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: ElevatedButton.icon(
        onPressed: () => _openFile(pdfUrl),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("View PDF"),
      ),
    );
  }

  /// 🔗 *Open File in Browser*
  void _openFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("❌ Could not open file: $url");
    }
  }
}
