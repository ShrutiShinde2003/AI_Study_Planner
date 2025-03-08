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
        'members': [user.uid], // ✅ Ensure it's stored as an array
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Group Created: ${groupRef.id}");
      _groupNameController.clear();
      Navigator.pop(context);
    } catch (e) {
      print("❌ Error creating group: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating group. Try again!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Group Chats")),
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
            itemCount: groups.length,
            itemBuilder: (context, index) {
              var group = groups[index];
              String groupId = group.id; // ✅ Correctly fetching document ID
              print("📌 Group Loaded: ${group['name']}"); // Debugging

              return ListTile(
                title: Text(group['name'],
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Tap to chat"),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupChatPage(
                        groupId: groupId, // ✅ Correct usage
                        groupName: group['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Create Group"),
              content: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(labelText: "Group Name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                TextButton(onPressed: _createGroup, child: Text("Create")),
              ],
            ),
          );
        },
      ),
    );
  }
}