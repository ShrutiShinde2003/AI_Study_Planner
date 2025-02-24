import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/todo_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the global To-Do collection (not inside user subcollection)
  CollectionReference get _todoCollection => _db.collection('tasks');

  // Get To-Do List stream for the current user
  Stream<List<TodoItem>> getTodoList() {
    final user = _auth.currentUser;
    if (user != null) {
      return _todoCollection
          .where('uid', isEqualTo: user.uid) // Fetch tasks for the current user
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } else {
      return Stream.value([]); // Return empty stream if the user is not authenticated
    }
  }

  // Get To-Do List once for the current user
  Future<List<TodoItem>> getTodoListOnce() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _todoCollection
            .where('uid', isEqualTo: user.uid)
            .get(); // Fetch all documents for the current user

        return snapshot.docs
            .map((doc) => TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      } catch (e) {
        print('Error fetching To-Do list: $e');
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }

  // Add To-Do item
  Future<void> addTodoItem(TodoItem todo) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _todoCollection.add({
          ...todo.toMap(), // Spread the map from TodoItem
          'uid': user.uid, // Store the UID for user-specific data
        });
      } catch (e) {
        print('Error adding To-Do item: $e');
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }

  // Update To-Do item
  Future<void> updateTodoItem(TodoItem todo) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _todoCollection.doc(todo.username).update(todo.toMap());
      } catch (e) {
        print('Error updating To-Do item: $e');
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }

  // Delete To-Do item
  Future<void> deleteTodoItem(String todoId) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _todoCollection.doc(todoId).delete();
      } catch (e) {
        print('Error deleting To-Do item: $e');
        rethrow;
      }
    } else {
      throw Exception("User is not authenticated");
    }
  }
}