import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  TaskCard({required this.taskId, required this.taskData});

  void _toggleTaskCompletion(String taskId, bool currentStatus) {
    if (taskId.isEmpty) {
      print("❌ Error: Task ID is empty!");
      return;
    }

    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isCompleted': !currentStatus, // Toggle status
    }).then((_) {
      print("✅ Task status updated!");
    }).catchError((error) {
      print("❌ Error updating task: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = taskData['isCompleted'] ?? false;

    // ✅ Ensure Subject Name is Fetched Correctly
    String subjectName = taskData.containsKey('subject') ? taskData['subject'] ?? 'No Subject' : 'No Subject';

    // ✅ Convert Firestore Timestamp to Formatted Date
    String dueDate = 'No Date';
    if (taskData.containsKey('dueDate')) {
      if (taskData['dueDate'] is Timestamp) {
        dueDate = (taskData['dueDate'] as Timestamp).toDate().toLocal().toString();
      } else if (taskData['dueDate'] is String) {
        dueDate = taskData['dueDate'];
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        title: Text(
          taskData['taskName'] ?? "No Task Name",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null, // Strike-through if completed
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Subject: $subjectName"), // ✅ Fixed Subject Display
            Text("Due: $dueDate"), // ✅ Properly Displays Date
          ],
        ),
        trailing: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            _toggleTaskCompletion(taskId, isCompleted);
          },
        ),
      ),
    );
  }
}
