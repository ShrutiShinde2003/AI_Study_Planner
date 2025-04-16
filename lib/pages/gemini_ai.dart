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
    backgroundColor: Colors.indigo.shade50,
    appBar: AppBar(
      title: Text("Subject Chats"),
      backgroundColor: Colors.indigo.shade50,
    ),
    body: subjects.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "No subjects added yet.\nGo to your profile to add subjects.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          )
        : ListView.separated(
            itemCount: subjects.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                title: Text(
                  subject,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.chat_bubble_outline, color: Colors.indigo[700]),
                ),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatSubjectScreen(subject: subject),
                    ),
                  );
                },
              );
            },
          ),
  );
}

}