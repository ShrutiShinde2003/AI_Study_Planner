// lib/models/todo_item.dart

class TodoItem {
  String username;
  String title;
  bool isCompleted;
  String uid;  // Added field to associate tasks with a user

  TodoItem({
    required this.username,
    required this.title,
    this.isCompleted = false,
    required this.uid,  // Include the user ID when creating a new task
  });

  // Convert To-Do item to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': username,
      'title': title,
      'isCompleted': isCompleted,
      'uid': uid,  // Add user ID to the map
    };
  }

  // Create a To-Do item from a Firestore document
  factory TodoItem.fromMap(Map<String, dynamic> map, String documentId) {
    return TodoItem(
      username: documentId,
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      uid: map['uid'] ?? '',  // Ensure the 'uid' is retrieved from the Firestore document
    );
  }
}
