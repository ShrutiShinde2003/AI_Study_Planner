import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Import Firestore

class Task {
  final String id;
  final String taskName;
  final String subject;
  final DateTime dueDate;
  final bool isCompleted;

  Task({
    required this.id,
    required this.taskName,
    required this.subject,
    required this.dueDate,
    required this.isCompleted,
  });

  // 🔹 Convert Firestore Document to `Task`
  factory Task.fromFirestore(DocumentSnapshot doc) { // ✅ Now recognized
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      taskName: data['taskName'] ?? 'No Task Name',
      subject: data['subject'] ?? 'No Subject',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isCompleted: data['isCompleted'] ?? false,
    );
  }
}
