import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

import '../services/firestore_service(groups).dart';
import '../models/message_model.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({
    required this.groupId,
    required this.groupName,
    Key? key,
  }) : super(key: key);

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseGroupService _groupService = FirebaseGroupService();
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _groupService.sendMessage(
        widget.groupId, _messageController.text.trim());
    _messageController.clear();
    FocusScope.of(context).unfocus();
  }

  void _addMemberByUsername() {
    final TextEditingController _usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: TextField(
          controller: _usernameController,
          decoration: const InputDecoration(hintText: "Enter username"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              String username = _usernameController.text.trim();
              Navigator.pop(context);
              bool success = await _groupService.addMemberByUsername(
                  widget.groupId, username);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'User added!' : '❌ User not found!'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

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

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _groupService.leaveGroup(widget.groupId);
              Navigator.pop(context);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadNote() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'jpg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading note to Cloudinary...')),
        );

        const cloudName = 'dusywpaom';
        const uploadPreset = 'flutter_uploads';

        // ✅ Use RAW upload URL
        final uploadUrl =
            Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');

        print("🚀 Uploading to: $uploadUrl");
        print("📁 File path: ${file.path}");
        print("📎 File name: $fileName");

        var request = http.MultipartRequest('POST', uploadUrl)
          ..fields['upload_preset'] = uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', file.path));

        var response = await request.send();

        final res = await http.Response.fromStream(response);
        print("📨 Raw response: ${res.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(res.body);
          String fileUrl = data['secure_url'];

          print("📦 Original Cloudinary URL: $fileUrl");

          // Fix just in case
          fileUrl = fileUrl.replaceFirst('/image/upload/', '/raw/upload/');
          print("🔧 Final Cloudinary URL used: $fileUrl");

          await _groupService.sendNoteMessage(
            widget.groupId,
            fileName,
            fileUrl,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Note uploaded successfully!')),
          );
        } else {
          throw Exception("Cloudinary upload failed: ${res.body}");
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: AppBar(
      title: Text(widget.groupName),
      actions: [
        IconButton(
            icon: const Icon(Icons.people),
            tooltip: "View Members",
            onPressed: _showGroupMembers),
        IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: "Add Member",
            onPressed: _addMemberByUsername),
        IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Group',
            onPressed: _confirmLeaveGroup),
      ],
    ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: Theme.of(context).brightness == Brightness.dark
              ? [Color(0xFF1A1A1A), Color.fromARGB(255, 41, 41, 41)]
              : [Color(0xFFF2F2F2), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _groupService.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return const Center(
                      child: Text("Something went wrong. Please try again."));
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return const Center(
                      child: Text("No messages yet. Start chatting!"));

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _auth.currentUser?.uid;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: Radius.circular(isMe ? 12 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(message.senderName,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700])),
                            const SizedBox(height: 4),
                            if (message.type == 'note' &&
                                message.fileUrl != null)
                              Builder(builder: (context) {
                                final url = message.fileUrl!;
                                final fileName =
                                    message.fileName ?? 'View Note';
                                final isImage = url.endsWith('.jpg') ||
                                    url.endsWith('.png');
                                final isPdf = url.endsWith('.pdf');

                                if (isImage) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              FullImageView(url: url),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(url,
                                          fit: BoxFit.cover,
                                          width: 180,
                                          height: 200),
                                    ),
                                  );
                                } else if (isPdf) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => PDFViewerPage(
                                            url: url,
                                            title: fileName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.picture_as_pdf,
                                            color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            fileName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  return GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(url);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode:
                                                LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  "Could not launch the file.")),
                                        );
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.insert_drive_file,
                                            size: 20, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            fileName,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: const TextStyle(
                                              decoration:
                                                  TextDecoration.underline,
                                              color: Colors.blueAccent,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              })
                            else
                              Text(message.text,
                                  style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: _pickAndUploadNote,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: _sendMessage,
                    child:
                        const Icon(Icons.send, size: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

class PDFViewerPage extends StatelessWidget {
  final String url;
  final String title;

  const PDFViewerPage({
    required this.url,
    required this.title,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: CircularProgressIndicator()),
      // flutter_cached_pdfview handles caching and errors
      // Use lower-level viewer widget for better control
      bottomSheet: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: PDF(
          fitEachPage: true,
          swipeHorizontal: false,
          onError: (error) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Error'),
                content: Text('❌ Failed to load PDF: $error'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  )
                ],
              ),
            );
          },
          onPageError: (page, error) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Page Error'),
                content: Text('❌ Error on page $page: $error'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  )
                ],
              ),
            );
          },
        ).cachedFromUrl(
          url,
          placeholder: (progress) => Center(child: Text('$progress %')),
          errorWidget: (error) => Center(child: Text('❌ Error: $error')),
        ),
      ),
    );
  }
}

class FullImageView extends StatelessWidget {
  final String url;
  const FullImageView({required this.url, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text("Image View"),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }
}
