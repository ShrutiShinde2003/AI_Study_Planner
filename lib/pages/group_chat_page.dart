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

  /// Send Message
  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    await _groupService.sendMessage(widget.groupId, _messageController.text.trim());
    _messageController.clear();
    FocusScope.of(context).unfocus(); // Dismiss keyboard after sending
  }

  /// Add Member to Group
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
              Navigator.pop(context); // Close dialog before making async call

              bool success = await _groupService.addMemberByUsername(widget.groupId, username);
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

  /// Show Group Members
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

  /// Leave Group Confirmation
  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _groupService.leaveGroup(widget.groupId);
              Navigator.pop(context); // Leave chat screen
            },
            child: const Text('Leave'),
          ),
        ],
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
          icon: const Icon(Icons.people),
          tooltip: "View Members",
          onPressed: _showGroupMembers,
        ),
        IconButton(
          icon: const Icon(Icons.person_add),
          tooltip: "Add Member",
          onPressed: _addMemberByUsername,
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app),
          tooltip: 'Leave Group',
          onPressed: _confirmLeaveGroup,
        ),
      ],
    ),
    body: Column(
      children: [
        // Chat Messages
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

              final messages = snapshot.data!;
              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == _auth.currentUser?.uid;

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.indigo[200] : Colors.grey[300],
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft: Radius.circular(isMe ? 12 : 0),
                          bottomRight: Radius.circular(isMe ? 0 : 12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.text,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Message Input
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  backgroundColor: Colors.white,
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}
