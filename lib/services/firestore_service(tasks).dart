import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/task_model.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _taskCollection => _db.collection('tasks');

  // 🔹 Get Tasks Stream for Current User
  Stream<List<TodoItem>> getTodoList() {
    final user = _auth.currentUser;
    if (user != null) {
      return _taskCollection
          .where('uid', isEqualTo: user.uid)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } else {
      return Stream.value([]);
    }
  }

  // 🔹 Add Task
  Future<void> addTask(String subject, String taskName, String description, DateTime dueDate) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _taskCollection.add({
          'uid': user.uid,          // Store User ID (Ensure consistency)
          'subjectName': subject,   // Subject Name
          'taskName': taskName,     // Task Name
          'description': description, // Task Description
          'dueDate': dueDate.toIso8601String(), // Convert Date to String
          'isCompleted': false, // Default: Task is Pending
          'createdAt': FieldValue.serverTimestamp(), // Auto-generated Timestamp
        });

        print("✅ Task added successfully!");
      } catch (e) {
        print("❌ Error adding task: $e");
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }

  // 🔹 Update Task (Mark as Completed or Edit Details)
  Future<void> updateTask(String taskId, Map<String, dynamic> updatedData) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _taskCollection.doc(taskId).update(updatedData);
        print("✅ Task updated successfully!");
      } catch (e) {
        print("❌ Error updating task: $e");
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }

  // 🔹 Delete Task
  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _taskCollection.doc(taskId).delete();
        print("✅ Task deleted successfully!");
      } catch (e) {
        print("❌ Error deleting task: $e");
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }
}
