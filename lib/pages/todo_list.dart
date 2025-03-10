import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/task_card.dart';
import 'notes_page.dart';
import 'package:intl/intl.dart'; // 🔹 For proper date formatting

class ToDoListPage extends StatefulWidget {
  final List<String> subjects;

  ToDoListPage({required this.subjects});

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Delete subject and its related tasks
  Future<void> deleteSubject(String subject) async {
    final user = _auth.currentUser;
    if (user == null) return;

    WriteBatch batch = _firestore.batch();

    try {
      // Query tasks belonging to the subject
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('uid', isEqualTo: user.uid)
          .where('subject', isEqualTo: subject)
          .get();

      // Add each task deletion to the batch
      for (var doc in tasksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Remove the subject from the user document
      DocumentReference userDocRef = _firestore.collection('users').doc(user.uid);
      batch.update(userDocRef, {
        'subjects': FieldValue.arrayRemove([subject])
      });

      await batch.commit();
      print("✅ Subject and its tasks deleted successfully");
    } catch (e) {
      print("❌ Error deleting subject: $e");
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
                      child: GestureDetector(
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text("Delete Subject"),
                              content: Text("Are you sure you want to delete '$subject' and all its tasks?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
                                TextButton(
                                  onPressed: () async {
                                    await deleteSubject(subject);
                                    Navigator.pop(context);
                                  },
                                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: ActionChip(
                          label: Text(subject),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => NotesPage(subject: subject)),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            )
          else
            Center(child: Text("No subjects available")),

          SizedBox(height: 10),

          Expanded(
            child: widget.subjects.isNotEmpty
                ? StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('tasks')
                        .where('uid', isEqualTo: _auth.currentUser?.uid)
                        .where('subject', whereIn: widget.subjects)
                        .orderBy('dueDate', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        print("❌ Firestore Error: ${snapshot.error}");
                        return Center(child: Text("Error loading tasks"));
                      }

                      if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
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

                          // ✅ Convert Firestore Timestamp to DateTime
                          DateTime? dueDate;
                          if (taskData['dueDate'] is Timestamp) {
                            dueDate = (taskData['dueDate'] as Timestamp).toDate();
                          } else if (taskData['dueDate'] is String) {
                            dueDate = DateTime.tryParse(taskData['dueDate']);
                          }

                          // ✅ Format Date Correctly
                          String formattedDate = dueDate != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(dueDate)
                              : 'No Due Date';

                          // ✅ Ensure Subject Name is Not Null
                          String subjectName = taskData['subject'] ?? 'No Subject';

                          return TaskCard(
                            taskId: taskDoc.id,
                            taskData: {
                              ...taskData,
                              'dueDate': formattedDate, // ✅ Pass formatted date
                              'subject': subjectName, // ✅ Ensures subject is passed correctly
                            },
                          );
                        },
                      );
                    },
                  )
                : Center(child: Text("No subjects available")),
          ),
        ],
      ),
    );
  }
}