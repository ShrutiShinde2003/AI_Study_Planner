import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "";
  String email = "";
  String profileImagePath = "";
  List<String> subjects = [];
  TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    loadProfileImage();
    fetchSubjects();
  }

  void fetchUserData() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      setState(() {
        userName = userDoc['userName'] ?? 'No Name';
        email = userDoc['email'] ?? 'No Email';
      });
    }
  }

  Future<void> loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      profileImagePath = prefs.getString('profileImagePath') ?? '';
    });
  }

  void fetchSubjects() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      List<dynamic> subjectsData = userDoc['subjects'] ?? [];
      setState(() {
        subjects = subjectsData.cast<String>();
      });
    }
  }

  void addSubject() async {
    String newSubject = _subjectController.text.trim();
    if (newSubject.isEmpty) return;

    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    await userDocRef.update({
      'subjects': FieldValue.arrayUnion([newSubject])
    });

    setState(() {
      subjects.add(newSubject);
    });

    _subjectController.clear();
  }

void deleteSubject(String subject) async {
  String userId = _auth.currentUser?.uid ?? '';
  if (userId.isEmpty) return;

  setState(() {
    subjects.remove(subject);  // Update UI immediately
  });

  DocumentReference userDocRef = _firestore.collection('users').doc(userId);

  await userDocRef.update({
    'subjects': FieldValue.arrayRemove([subject])
  });

  // Delete all tasks related to this subject
  QuerySnapshot tasksSnapshot = await _firestore
      .collection('tasks')
      .where('userId', isEqualTo: userId)
      .where('subject', isEqualTo: subject)
      .get();

  for (QueryDocumentSnapshot taskDoc in tasksSnapshot.docs) {
    await _firestore.collection('tasks').doc(taskDoc.id).delete();
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    resizeToAvoidBottomInset: true, // ✅ Allows scrolling when keyboard appears
    appBar: AppBar(
      title: Text("Profile"),
      automaticallyImplyLeading: false,  // 🚀 Removes the back button
      actions: [
        IconButton(
          icon: Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SettingsPage()),
            );
          },
        ),
      ],
    ),
    body: SingleChildScrollView( // ✅ Prevents overflow
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: profileImagePath.isNotEmpty
                    ? (profileImagePath.contains("assets/")
                        ? AssetImage(profileImagePath) as ImageProvider
                        : FileImage(File(profileImagePath)))
                    : null,
                child: profileImagePath.isEmpty
                    ? Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 10),
            Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Subjects:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            subjects.isEmpty
                ? Text("No subjects added", style: TextStyle(color: Colors.grey))
                : Column(
                    children: subjects.map((subject) {
                      return ListTile(
                        leading: Icon(Icons.book, color: Colors.blue),
                        title: Text(subject, style: TextStyle(fontSize: 16)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteSubject(subject),
                        ),
                      );
                    }).toList(),
                  ),
            SizedBox(height: 10),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Add Subject",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: addSubject,
              child: Text("Add Subject"),
            ),
          ],
        ),
      ),
    ),
  );
}
}