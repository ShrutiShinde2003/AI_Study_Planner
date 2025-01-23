import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/todo_item.dart';
import 'package:study_planner/services/firestore_service.dart';

class TodoListPage extends StatefulWidget {
  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _todoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Add your logout logic here
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _todoController,
                    decoration: InputDecoration(
                      labelText: 'New To-Do',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTodoItem,
                  child: Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TodoItem>>(
              stream: _firestoreService.getTodoList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No To-Do items'));
                }

                final todoList = snapshot.data!;
                return ListView.builder(
                  itemCount: todoList.length,
                  itemBuilder: (context, index) {
                    final todo = todoList[index];
                    return ListTile(
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          decoration: todo.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (value) {
                          _toggleTodoCompletion(todo, value!);
                        },
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteTodoItem(todo.username);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Method to add a new To-Do item
  void _addTodoItem() {
    if (_todoController.text.isNotEmpty) {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newTodo = TodoItem(
          username: user.displayName ?? 'default', // Firestore will generate the ID
          title: _todoController.text.trim(),
          uid: user.uid,  // Use the current user's UID
        );
        _firestoreService.addTodoItem(newTodo);
        _todoController.clear();
      }
    }
  }

  // Method to toggle completion status of a To-Do item
  void _toggleTodoCompletion(TodoItem todo, bool isCompleted) {
    todo.isCompleted = isCompleted;
    _firestoreService.updateTodoItem(todo);
  }

  // Method to delete a To-Do item
  void _deleteTodoItem(String id) {
    _firestoreService.deleteTodoItem(id);
  }
}
