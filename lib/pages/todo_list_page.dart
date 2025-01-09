import 'package:flutter/material.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({Key? key}) : super(key: key);

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final List<Map<String, dynamic>> _todoList = [];
  final TextEditingController _todoController = TextEditingController();

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
            child: ListView.builder(
              itemCount: _todoList.length,
              itemBuilder: (context, index) {
                final todo = _todoList[index];
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
                      setState(() {
                        todo['completed'] = value!;
                      });
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeTodoItem(index),
                  ),
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
      setState(() {
        _todoList.add({
          'title': _todoController.text,
          'completed': false,
        });
        _todoController.clear();
      });
    }
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoList.removeAt(index);
    });
  }
}
