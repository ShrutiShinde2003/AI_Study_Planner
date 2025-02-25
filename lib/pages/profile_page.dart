import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'todo_list.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _subjectController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> subjects = [];

  @override
void initState() {
  super.initState();
  fetchSubjects(); // ✅ Load subjects when Profile Page opens
}

void fetchSubjects() async {
  String userId = _auth.currentUser?.uid ?? '';

  if (userId.isEmpty) {
    print("❌ No user logged in.");
    return;
  }

  DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

  if (userDoc.exists && userDoc.data() != null) {
    setState(() {
      subjects = List<String>.from((userDoc.data() as Map<String, dynamic>)['subjects'] ?? []);
    });
  } else {
    print("⚠️ No subjects found in Firestore.");
  }
}


  // 🔹 Add new subject to Firestore
  void _addSubject() async {
    String userId = _auth.currentUser!.uid;
    String subject = _subjectController.text.trim();

    if (subject.isNotEmpty) {
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'subjects': FieldValue.arrayUnion([subject])
      });

      _subjectController.clear();
      fetchSubjects(); // 🔹 Refresh the subjects list after adding
    }
  }

  // 🔹 Delete a subject & its tasks
  void _deleteSubject(String subject) async {
    String userId = _auth.currentUser!.uid;

    try {
      // ✅ Delete all tasks related to this subject first
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('uid', isEqualTo: userId)
          .where('subjectName', isEqualTo: subject)
          .get();

      for (var doc in tasksSnapshot.docs) {
        await doc.reference.delete(); // 🔥 Delete each task
      }

      // ✅ Now delete the subject from the user’s subject list
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'subjects': FieldValue.arrayRemove([subject]) // Remove subject
      });

      fetchSubjects(); // 🔹 Refresh list after deleting
      print("✅ Subject '$subject' and all its tasks deleted!");
    } catch (e) {
      print("❌ Error deleting subject and tasks: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Add Subject",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addSubject,
                ),
              ),
            ),
            SizedBox(height: 20),

            // 🔹 Display Subjects List
            Expanded(
              child: subjects.isEmpty
                  ? Center(child: Text("No subjects added yet"))
                  : ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(subjects[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSubject(subjects[index]),
                          ),
                        );
                      },
                    ),
            ),

            SizedBox(height: 20),

            // 🔹 Go to To-Do List Button
            ElevatedButton(
              onPressed: () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;

                DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
                List<String> subjects = List<String>.from(userDoc['subjects'] ?? []);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToDoListPage(
                      subjects: subjects,
                      subject: subjects.isNotEmpty ? subjects[0] : '',
                    ),
                  ),
                );
              },
              child: Text("Go to To-Do List"),
            ),
          ],
        ),
      ),
    );
  }
}
