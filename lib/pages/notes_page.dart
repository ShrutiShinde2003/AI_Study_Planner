import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_item.dart';

class NotesPage extends StatefulWidget {
  final String subject;

  NotesPage({required this.subject});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  TextEditingController taskController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController dueDateController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;
  CollectionReference ref = FirebaseFirestore.instance.collection('tasks');

  void addTaskToFirebase() async {
    if (taskController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        dueDateController.text.isNotEmpty) {
      final user = auth.currentUser!;
      String uid = user.uid;

      TaskModel newTask = TaskModel(
        uid: uid,
        subject: widget.subject,
        task: taskController.text.trim(),
        description: descriptionController.text.trim(),
        dueDate: dueDateController.text.trim(),
        timeCreated: DateTime.now(),
      );

      await ref.add(newTask.toMap()).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Task Added Successfully!")),
        );
        Navigator.pop(context); // Go back to To-Do List page after adding task
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error adding task: $error")),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task for ${widget.subject}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: InputDecoration(labelText: "Enter Task"),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: "Enter Description"),
            ),
            TextField(
              controller: dueDateController,
              decoration: InputDecoration(
                labelText: "Enter Due Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: addTaskToFirebase,
              child: Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }
}
