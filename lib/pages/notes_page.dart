import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart'; // Import TaskModel
import '../widgets/task_card.dart'; // Import TaskCard UI

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

  // Function to add task to Firebase
  void addTaskToFirebase() async {
    if (taskController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        dueDateController.text.isNotEmpty) {
      final user = auth.currentUser!;
      String uid = user.uid;

      // Create a TaskModel instance
      TaskModel newTask = TaskModel(
        uid: uid,
        subject: widget.subject,
        task: taskController.text.trim(),
        description: descriptionController.text.trim(),
        dueDate: dueDateController.text.trim(),
        timeCreated: DateTime.now(),
      );

      // Add the task data to Firestore using the generated document ID
      await ref.add(newTask.toMap()).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Task Added Successfully!")),
        );
        taskController.clear();
        descriptionController.clear();
        dueDateController.clear();
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
      appBar: AppBar(title: Text("Tasks for ${widget.subject}")),
      body: Column(
        children: [
          Padding(
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where("subject", isEqualTo: widget.subject)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No tasks found"));
                }

                var tasks = snapshot.data!.docs.map((doc) {
                  return TaskModel.fromMap(doc.data() as Map<String, dynamic>);
                }).toList();

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    return TaskCard(task: tasks[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
