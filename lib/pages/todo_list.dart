import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notes_page.dart';
import '../models/task_item.dart';
import '../pages/task_card.dart';

class ToDoListPage extends StatefulWidget {
  final List<String> subjects; // Required subjects list

  ToDoListPage({required this.subjects, required String subject});

  @override
  _ToDoListPageState createState() => _ToDoListPageState();

}

class _ToDoListPageState extends State<ToDoListPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("To-Do List")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: widget.subjects.length,
          itemBuilder: (context, index) {
            String subject = widget.subjects[index];

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    title: Text(subject, style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Icon(Icons.add_task, color: Colors.blue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotesPage(subject: subject),
                        ),
                      );
                    },
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tasks')
                        .where("subject", isEqualTo: subject)
                        .where("uid", isEqualTo: auth.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("No tasks yet. Tap + to add a task."),
                        );
                      }

                      var tasks = snapshot.data!.docs.map((doc) {
                        return TaskModel.fromMap(doc.data() as Map<String, dynamic>);
                      }).toList();

                      return Column(
                        children: tasks.map((task) => TaskCard(task: task)).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
