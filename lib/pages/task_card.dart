import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final VoidCallback? onCompleteTask; // ✅ Callback for marking tasks as complete
  final VoidCallback? onDeleteTask;   // ✅ Callback for deleting tasks

  TaskCard({
    required this.taskId,
    required this.taskData,
    this.onCompleteTask,  // ✅ Ensure these parameters exist
    this.onDeleteTask, 
  });

  /// 🔹 Toggle task completion status in Firestore
  void _toggleTaskCompletion(String taskId, bool currentStatus) {
    FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'isCompleted': !currentStatus,
      'completedAt': !currentStatus ? FieldValue.serverTimestamp() : null,
    }).then((_) {
      print("✅ Task status updated!");
    }).catchError((error) {
      print("❌ Error updating task: $error");
    });
  }

  /// 🔹 Delete Task (If Completed, Save to `completedTasks`)
  void _deleteTask(BuildContext context) async {
    bool isCompleted = taskData["isCompleted"] ?? false;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      if (isCompleted) {
        // ✅ Move to completedTasks before deleting
        await firestore.collection('completedTasks').doc(taskId).set(taskData);
      }

      // ✅ Delete from tasks collection
      await firestore.collection('tasks').doc(taskId).delete();
      print("✅ Task deleted successfully!");

      // ✅ Call onDeleteTask callback to update UI
      if (onDeleteTask != null) onDeleteTask!();
    } catch (e) {
      print("❌ Error deleting task: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = taskData["isCompleted"] ?? false;
    String taskName = taskData['taskName'] ?? "No Task Name";

    // ✅ Convert Firestore Timestamp to Formatted Date
    String dueDate = 'No Due Date';
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
        leading: Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey,
        ),
        title: Text(
          taskName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: isCompleted ? TextDecoration.lineThrough : null, // ✅ Strike-through if completed
          ),
        ),
        subtitle: Text("Due: $dueDate"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompleted) // ✅ Show only if task is not completed
              IconButton(
                icon: Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  _toggleTaskCompletion(taskId, isCompleted);
                  if (onCompleteTask != null) onCompleteTask!();
                },
              ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red), // ✅ DELETE Button
              onPressed: () {
                // ✅ Show Confirmation Dialog Before Deleting
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Delete Task"),
                    content: Text("Are you sure you want to delete this task?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteTask(context);
                        },
                        child: Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
