import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/task_card.dart';
import 'notes_page.dart';

class ToDoListPage extends StatefulWidget {
  final List<String> subjects;
  final String subject;

  ToDoListPage({required this.subjects, required this.subject});

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> tasks = []; // Store tasks here

  @override
  void initState() {
    super.initState();
    fetchTasks(); // ✅ Fetch tasks when the To-Do List page opens
  }

  // 🔹 Fetch all tasks from Firestore
  void fetchTasks() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      print("❌ No user logged in.");
      return;
    }

    QuerySnapshot taskSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('uid', isEqualTo: userId)
        .orderBy('dueDate', descending: false) // ✅ Keep sorting tasks
        .get();

    if (taskSnapshot.docs.isNotEmpty) {
      setState(() {
        tasks = taskSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
      print("📌 Total Tasks Retrieved: ${tasks.length}");
    } else {
      print("⚠️ No tasks found in Firestore.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("To-Do List")),
      body: Column(
        children: [
          // 🔹 Show Subjects at the Top (Click to Open NotesPage)
          if (widget.subjects.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 10),
                  ...widget.subjects.map((subject) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        label: Text(subject),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesPage(subject: subject),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            )
          else
            Center(child: Text("No subjects available")),

          SizedBox(height: 10),

          // 🔹 Show ALL Tasks from ALL Subjects
          Expanded(
            child: tasks.isEmpty
                ? Center(child: Text("No tasks available")) // ✅ Show message if no tasks
                : ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      var taskData = tasks[index];
                      return TaskCard(
                        taskId: taskData['taskId'] ?? '',
                        taskData: taskData,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
