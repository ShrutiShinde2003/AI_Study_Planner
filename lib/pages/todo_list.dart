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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("To-Do List"),
      automaticallyImplyLeading: false,  // 🚀 Removes the back button
      ),
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

          // 🔹 Show ALL Tasks from ALL Subjects (REAL-TIME UPDATES)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tasks')
                  .where('uid', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('dueDate', descending: false) // ✅ Sort tasks
                  .snapshots(), // ✅ Listen for real-time changes
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator()); // 🔹 Show loading
                }

                if (snapshot.hasError) {
                  print("❌ Firestore Error: ${snapshot.error}");
                  return Center(child: Text("Error loading tasks"));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("⚠️ No tasks found!");
                  return Center(child: Text("No tasks available"));
                }

                var tasks = snapshot.data!.docs;

                print("📌 Total Tasks Retrieved: ${tasks.length}");

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    var taskDoc = tasks[index];
                    var taskData = taskDoc.data() as Map<String, dynamic>;

                    return TaskCard(
                      taskId: taskDoc.id, // ✅ Pass correct task ID
                      taskData: taskData,
                    );
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
