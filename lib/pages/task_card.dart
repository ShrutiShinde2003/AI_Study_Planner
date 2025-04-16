import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final VoidCallback? onCompleteTask;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

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

      if (!currentStatus) {
        _firebaseMessaging.subscribeToTopic("task_completed_$taskId");
      }

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
  String subject = taskData['subject'] ?? 'No Subject';
  String description = taskData['description'] ?? 'No Description';

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _toggleTaskCompletion(taskId, isCompleted),
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isCompleted ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                taskName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subject,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.indigo,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "Due: $dueDate",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
}