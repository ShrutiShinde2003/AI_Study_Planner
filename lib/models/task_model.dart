import 'package:cloud_firestore/cloud_firestore.dart';

class TodoItem {
  final String id;
  final String uid;
  final String subjectName;
  final String taskName;
  final String description;
  final DateTime dueDate;
  final bool isCompleted;

  TodoItem({
    required this.id,
    required this.uid,
    required this.subjectName,
    required this.taskName,
    required this.description,
    required this.dueDate,
    required this.isCompleted,
  });

  // 🔹 Convert Firestore Document to TodoItem Object
  factory TodoItem.fromMap(Map<String, dynamic> data, String documentId) {
    return TodoItem(
      id: documentId,
      uid: data['uid'] ?? '',
      subjectName: data['subjectName'] ?? '',
      taskName: data['taskName'] ?? '',
      description: data['description'] ?? '',
      dueDate: DateTime.parse(data['dueDate'] ?? DateTime.now().toIso8601String()),
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  // 🔹 Convert TodoItem to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'subjectName': subjectName,
      'taskName': taskName,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }
}
