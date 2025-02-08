import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_planner/pages/todo_list.dart';

class ProfilePage extends StatefulWidget {
  final String userId; // Accept userId

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<String> subjects = []; // List to store subjects
  TextEditingController subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchSubjects(); // Load subjects from Firestore
  }

  // Function to fetch subjects from Firestore
  void fetchSubjects() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    if (userDoc.exists) {
      setState(() {
        subjects = List<String>.from(userDoc['subjects'] ?? []);
      });
    }
  }

  // Function to add a new subject to Firestore
  void addSubject() async {
    if (subjectController.text.isNotEmpty) {
      setState(() {
        subjects.add(subjectController.text);
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'subjects': subjects}); // Update Firestore

      subjectController.clear();
    }
  }

  // Function to edit a subject in Firestore
  void editSubject(int index) {
    subjectController.text = subjects[index];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Subject"),
          content: TextField(
            controller: subjectController,
            decoration: InputDecoration(hintText: "Enter subject name"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  subjects[index] = subjectController.text;
                });

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.userId)
                    .update({'subjects': subjects}); // Update Firestore

                subjectController.clear();
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Function to delete a subject from Firestore
  void deleteSubject(int index) async {
    setState(() {
      subjects.removeAt(index);
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'subjects': subjects}); // Update Firestore
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile - Subjects")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: InputDecoration(
                labelText: "Enter Subject",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: addSubject,
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(subjects[index]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => editSubject(index),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteSubject(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (subjects.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ToDoListPage(subjects: subjects, subject: ''),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please add at least one subject!")),
                  );
                }
              },
              child: Text("Go to To-Do List"),
            ),
          ],
        ),
      ),
    );
  }
}
