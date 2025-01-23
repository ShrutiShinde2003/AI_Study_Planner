import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _todoController = TextEditingController();

  // Reference to the Firestore collection for the current user
  final CollectionReference _userTodos =
      FirebaseFirestore.instance.collection('users').doc('user_id').collection('todos');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do List'),
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
                    decoration: const InputDecoration(
                      labelText: 'New To-Do',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTodoItem,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userTodos.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading to-dos.'));
                }
                final todos = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return ListTile(
                      title: Text(
                        todo['title'],
                        style: TextStyle(
                          decoration: todo['completed']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: todo['completed'],
                        onChanged: (value) {
                          _updateTodoItem(todo.id, value!);
                        },
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTodoItem(todo.id),
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

  void _addTodoItem() {
    if (_todoController.text.isNotEmpty) {
      _userTodos.add({
        'title': _todoController.text,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _todoController.clear();
    }
  }

  void _updateTodoItem(String id, bool completed) {
    _userTodos.doc(id).update({'completed': completed});
  }

  void _deleteTodoItem(String id) {
    _userTodos.doc(id).delete();
  }
}
