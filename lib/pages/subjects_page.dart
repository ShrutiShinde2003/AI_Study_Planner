import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> subjects = [];
  final TextEditingController _subjectController = TextEditingController();

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
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Are you sure?"),
        content: Text("Deleting this subject will remove all related tasks."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == null || !confirmDelete) return;

    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    setState(() {
      subjects.remove(subject);
    });

    DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    await userDocRef.update({
      'subjects': FieldValue.arrayRemove([subject])
    });

    QuerySnapshot tasksSnapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('subject', isEqualTo: subject)
        .get();

    for (QueryDocumentSnapshot taskDoc in tasksSnapshot.docs) {
      await _firestore.collection('tasks').doc(taskDoc.id).delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Subject and all related tasks deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Subjects")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            subjects.isEmpty
                ? Text("No subjects added",
                    style: TextStyle(color: Colors.grey))
                : Expanded(
                    child: ListView(
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
                  ),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(labelText: "Add Subject"),
            ),
            SizedBox(height: 16), // Adds spacing
            Center(
              // Centers the button
              child: ElevatedButton(
                onPressed: addSubject,
                child: Text("Add Subject"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
