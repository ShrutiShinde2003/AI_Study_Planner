import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_chat_page.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _groupNameController = TextEditingController();

  void _createGroup() async {
    String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Group name cannot be empty!")),
      );
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentReference groupRef = _firestore.collection('groups').doc();

      await groupRef.set({
        'name': groupName,
        'createdBy': user.uid,
        'members': [user.uid], // Ensure it's stored as an array
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(" Group Created: ${groupRef.id}");
      _groupNameController.clear();
      Navigator.pop(context);
    } catch (e) {
      print(" Error creating group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating group. Try again!")),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Group Chats"),
      backgroundColor: Colors.indigo.shade50,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
    ),
    backgroundColor: Colors.indigo.shade50,
    body: StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('groups')
          .where('members', arrayContains: _auth.currentUser?.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("❌ Firestore Error: ${snapshot.error}");
          return Center(
              child: Text("Something went wrong: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No groups available. Create one!"));
        }

        var groups = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            var group = groups[index];
            String groupId = group.id;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              margin: EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                title: Text(
                  group['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text("Tap to chat"),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatPage(
                        groupId: groupId,
                        groupName: group['name'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.blueAccent,
      child: Icon(Icons.add, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Create Group"),
            content: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _createGroup,
                child: Text("Create"),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

}
