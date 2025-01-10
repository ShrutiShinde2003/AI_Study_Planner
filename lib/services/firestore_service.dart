// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/todo_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reference to the To-Do collection for the current user
  CollectionReference get _todoCollection =>
      _db.collection('users').doc(_auth.currentUser?.uid).collection('todos');

  // Get To-Do List stream
  Stream<List<TodoItem>> getTodoList() {
    return _todoCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              TodoItem.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Add To-Do item
  Future<void> addTodoItem(TodoItem todo) {
    return _todoCollection.add(todo.toMap());
  }

  // Update To-Do item
  Future<void> updateTodoItem(TodoItem todo) {
    return _todoCollection.doc(todo.id).update(todo.toMap());
  }

  // Delete To-Do item
  Future<void> deleteTodoItem(String id) {
    return _todoCollection.doc(id).delete();
  }
}