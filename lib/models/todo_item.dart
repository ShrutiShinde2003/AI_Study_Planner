// lib/models/todo_item.dart

class TodoItem {
  String id;
  String title;
  bool isCompleted;

  TodoItem({required this.id, required this.title, this.isCompleted = false});

  // Convert To-Do item to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  // Create a To-Do item from a Firestore document
  factory TodoItem.fromMap(Map<String, dynamic> map, String documentId) {
    return TodoItem(
      id: documentId,
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}