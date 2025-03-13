import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service(groups).dart';
import '../models/message_model.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatPage({required this.groupId, required this.groupName, Key? key}) : super(key: key);

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseGroupService _groupService = FirebaseGroupService();
  final TextEditingController _messageController = TextEditingController();

  /// ✅ Send Message
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _groupService.sendMessage(widget.groupId, _messageController.text.trim());
    _messageController.clear();
    FocusScope.of(context).unfocus(); // ✅ Dismiss keyboard after sending
  }

  /// ✅ Add Member to Group
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              String username = _usernameController.text.trim();
              Navigator.pop(context); // ✅ Close dialog before making async call

              bool success = await _groupService.addMemberByUsername(widget.groupId, username);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? '✅ User added!' : '❌ User not found!'),
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

  /// ✅ Show Group Members
  void _showGroupMembers() async {
    List<Map<String, dynamic>> members = await _groupService.getGroupMembers(widget.groupId);

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
          IconButton(icon: const Icon(Icons.people), onPressed: _showGroupMembers),
          IconButton(icon: const Icon(Icons.person_add), onPressed: _addMemberByUsername),
        ],
      ),
      body: Column(
        children: [
          /// ✅ Chat Messages
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _groupService.getGroupMessages(widget.groupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong. Please try again."));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No messages yet. Start chatting!"));
                }

                var messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isMe = message.senderId == _auth.currentUser?.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.senderName, // ✅ Shows sender's username above message
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            const SizedBox(height: 3),
                            Text(message.text, style: const TextStyle(fontSize: 16)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
}