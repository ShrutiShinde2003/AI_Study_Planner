import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _taskCollection => _db.collection('tasks');

  // 🔹 Get Tasks Stream for Current User (Sorted by Due Date)
  Stream<List<Task>> getTodoList() {
    final user = _auth.currentUser;
    if (user != null) {
      return _taskCollection
          .where('uid', isEqualTo: user.uid)
          .orderBy('dueDate', descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) =>
                Task.fromFirestore(doc)) // ✅ Uses Task instead of TodoItem
            .toList();
      });
    } else {
      return Stream.value([]);
    }
  }

  // 🔹 Add Task (Stores `dueDate` as Firestore `Timestamp`)
  Future<void> addTask({
    required String subject, // ✅ Changed from subjectName to subject
    required String taskName,
    required String description,
    required DateTime dueDate,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('tasks').add({
      'uid': user.uid,
      'subject': subject, // ✅ Ensure Firestore stores "subject"
      'taskName': taskName,
      'description': description,
      'dueDate': dueDate,
      'isCompleted': false,
    });
  }

  // 🔹 Update Task (Ensure Only the Owner Can Update)
  Future<void> updateTask(
      String taskId, Map<String, dynamic> updatedData) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot taskSnapshot = await _taskCollection.doc(taskId).get();

        if (!taskSnapshot.exists || taskSnapshot['uid'] != user.uid) {
          throw Exception("Unauthorized: You can only update your own tasks.");
        }

        // ⚠️ Prevent 'uid' field from being altered
        if (updatedData.containsKey('uid') && updatedData['uid'] != user.uid) {
          throw Exception("Cannot change task ownership.");
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
