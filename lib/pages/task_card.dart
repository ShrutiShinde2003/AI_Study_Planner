import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final VoidCallback? onCompleteTask;
  final VoidCallback? onDeleteTask;

  TaskCard({
    required this.taskId,
    required this.taskData,
    this.onCompleteTask,
    this.onDeleteTask,
  });

  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'isCompleted': !currentStatus,
        'completedAt': !currentStatus ? FieldValue.serverTimestamp() : null,
      });

      if (onCompleteTask != null) onCompleteTask!();
    } catch (error) {
      print("❌ Error updating task: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = taskData["isCompleted"] ?? false;
    String taskName = taskData['taskName'] ?? "No Task Name";
    String dueDate = taskData['dueDate'] ?? 'No Due Date';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          taskName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text("Due: $dueDate"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompleted)
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  _toggleTaskCompletion(taskId, isCompleted);
                },
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: onDeleteTask,
            ),
          ],
        ),
      ),
    );
  }
}
