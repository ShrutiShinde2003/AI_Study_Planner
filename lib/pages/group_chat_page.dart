import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  GroupChatPage({required this.groupId, required this.groupName});

  @override
  _GroupChatPageState createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  /// ✅ Send message function
  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 🔍 Fetch current user's username
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      String? userName = (userDoc.data() as Map<String, dynamic>?)?['userName'] ?? 'Unknown';

      await _firestore
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': userName, // ✅ Store username instead of email
        'text': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ Message Sent!");
      _messageController.clear();
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  /// ✅ Add member by username function
  void _addMemberByUsername(BuildContext context) {
    final TextEditingController _usernameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Member to Group'),
        content: TextField(
          controller: _usernameController,
          decoration: InputDecoration(hintText: "Enter username"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String username = _usernameController.text.trim();
              if (username.isEmpty) return;

              try {
                QuerySnapshot userSnapshot = await _firestore
                    .collection('users')
                    .where('userName', isEqualTo: username)
                    .limit(1)
                    .get();

                if (userSnapshot.docs.isNotEmpty) {
                  String userIdToAdd = userSnapshot.docs.first.id;

                  await _firestore.collection('groups').doc(widget.groupId).update({
                    'members': FieldValue.arrayUnion([userIdToAdd])
                  });

                  print("✅ User added to group");
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User added successfully!')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User not found!')),
                  );
                }
              } catch (e) {
                print("❌ Error adding member: $e");
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding member!')),
                );
              }
            },
            child: Text("Add"),
          ),
        ],
      ),
    );
  }

  /// ✅ Show group members function
  void _showGroupMembers(BuildContext context) async {
    try {
      DocumentSnapshot groupSnapshot =
          await _firestore.collection('groups').doc(widget.groupId).get();

      List members = groupSnapshot['members'];

      List<DocumentSnapshot> userSnapshots = await Future.wait(
        members.map((memberId) => _firestore.collection('users').doc(memberId).get()),
      );

      showModalBottomSheet(
        context: context,
        builder: (context) => ListView(
          padding: EdgeInsets.all(16),
          children: userSnapshots.map((userDoc) {
            var userData = userDoc.data() as Map<String, dynamic>?;
            return ListTile(
              leading: Icon(Icons.person),
              title: Text(userData?['userName'] ?? 'Unknown User'),
              subtitle: Text(userData?['email'] ?? ''),
            );
          }).toList(),
        ),
      );
    } catch (e) {
      print("❌ Error fetching members: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            onPressed: () => _showGroupMembers(context),
          ),
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: () => _addMemberByUsername(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('groups')
                    .doc(widget.groupId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No messages yet. Start chatting!"));
                  }

                  var messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      var message = messages[index];
                      bool isMe = message['senderId'] == _auth.currentUser?.uid;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blueAccent : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                message['senderName'] ?? 'Unknown', // ✅ Show username here
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? Colors.white : Colors.black),
                              ),
                              SizedBox(height: 3),
                              Text(
                                message['text'],
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
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
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Enter message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: Icon(Icons.send, color: Colors.white),
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
