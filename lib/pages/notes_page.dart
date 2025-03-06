import 'package:flutter/material.dart';
import '../services/firestore_service(tasks).dart';

class NotesPage extends StatefulWidget {
  final String subject;
  NotesPage({required this.subject});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  final FirestoreService _firestoreService = FirestoreService(); // 🔹 FirestoreService Instance

  void _addTask() async {
    if (_taskNameController.text.isEmpty || _selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    await _firestoreService.addTask(
      widget.subject,
      _taskNameController.text,
      _descriptionController.text,
      _selectedDueDate!,
    );

    Navigator.pop(context); // 🔹 Go back to To-Do List after adding the task
  }

  // 🔹 UI for Task Adding
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task - ${widget.subject}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _taskNameController, decoration: InputDecoration(labelText: "Task Name")),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: "Description")),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(_selectedDueDate == null ? "Select Due Date" : "Due: ${_selectedDueDate!.toLocal()}"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addTask,
              child: Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }
}
