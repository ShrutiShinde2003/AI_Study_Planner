import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/task_model.dart';

// class FirestoreService {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _taskCollection => _db.collection('tasks');

  // 🔹 Get Tasks Stream for Current User (Sorted by Due Date)
  Stream<List<TodoItem>> getTodoList() {
    final user = _auth.currentUser;
    if (user != null) {
      return _taskCollection
          .where('uid', isEqualTo: user.uid)
          .orderBy('dueDate', descending: false) // ✅ Ensures sorted tasks
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

  // 🔹 Add Task (Stores `dueDate` as Firestore `Timestamp`)
  Future<void> addTask(String subject, String taskName, String description, DateTime dueDate) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _taskCollection.add({
          'uid': user.uid,          // ✅ Store User ID
          'subject': subject,       // ✅ Fixed field name (was `subjectName`)
          'taskName': taskName,     // ✅ Task Name
          'description': description, // ✅ Task Description
          'dueDate': Timestamp.fromDate(dueDate), // ✅ Store as Firestore Timestamp
          'isCompleted': false, // ✅ Default: Task is Pending
          'createdAt': FieldValue.serverTimestamp(), // ✅ Auto-generated Timestamp
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

  // 🔹 Update Task (Ensure Only the Owner Can Update)
  Future<void> updateTask(String taskId, Map<String, dynamic> updatedData) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot taskSnapshot = await _taskCollection.doc(taskId).get();
        
        if (!taskSnapshot.exists || taskSnapshot['uid'] != user.uid) {
          throw Exception("Unauthorized: You can only update your own tasks.");
        }

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

  // 🔹 Delete Task (Ensure Only the Owner Can Delete)
  Future<void> deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot taskSnapshot = await _taskCollection.doc(taskId).get();

        if (!taskSnapshot.exists || taskSnapshot['uid'] != user.uid) {
          throw Exception("Unauthorized: You can only delete your own tasks.");
        }

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
