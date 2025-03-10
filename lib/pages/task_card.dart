import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final VoidCallback? onCompleteTask;

  TaskCard({
    required this.taskId,
    required this.taskData,
    this.onCompleteTask,
  });

  /// 🔄 Toggle task completion status
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
        leading: GestureDetector(
          onTap: () => _toggleTaskCompletion(taskId, isCompleted),
          child: Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey,
            size: 28,
          ),
        ),
        title: Text(
          taskName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "Due: $dueDate",
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        // ❌ Removed trailing delete button
      ),
    );
  }
}
