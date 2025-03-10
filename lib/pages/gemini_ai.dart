import 'package:study_planner/config/api_keys.dart'; // Import API key file
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/pages/chat_subject_screeen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  void fetchSubjects() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      List<dynamic> subjectsData = userDoc['subjects'] ?? [];
      setState(() {
        subjects = subjectsData.cast<String>();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subject Chats")),
      body: subjects.isEmpty
          ? Center(child: Text("No subjects added. Add subjects in Profile."))
          : ListView.builder(
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(subjects[index]),
                  leading: Icon(Icons.chat, color: Colors.blue),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatSubjectScreen(subject: subjects[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
