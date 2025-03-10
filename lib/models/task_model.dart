import 'package:cloud_firestore/cloud_firestore.dart';

class TodoItem {
  final String id;
  final String uid;
  final String subject;
  final String taskName;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.uid,
    required this.subject,
    required this.taskName,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
  });

  factory TodoItem.fromMap(Map<String, dynamic> data, String documentId) {
    return TodoItem(
      id: documentId,
      uid: data['uid'] ?? '',
      subject: data['subject'] ?? '',
      taskName: data['taskName'] ?? '',
      description: data['description'] ?? '',
      dueDate: DateTime.parse(data['dueDate'] ?? DateTime.now().toIso8601String()),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'subject': subject,
      'taskName': taskName,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
