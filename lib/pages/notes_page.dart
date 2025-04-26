import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service(tasks).dart';

class NotesPage extends StatefulWidget {
  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;
  final FirestoreService _firestoreService = FirestoreService();
  String? _selectedSubject;
  List<String> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  // 🔹 Fetch subjects from Firestore
  Future<void> _fetchSubjects() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      List<String> subjects = List<String>.from(userDoc['subjects'] ?? []);
      setState(() {
        _subjects = subjects;
        if (_subjects.isNotEmpty) {
          _selectedSubject = _subjects.first;
        }
      });
    }
  }

  void _addTask() async {
  if (_taskNameController.text.isEmpty ||
      _selectedDueDate == null ||
      _selectedSubject == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please fill in all fields")),
    );
    return;
  }

  await _firestoreService.addTask(
    subject: _selectedSubject!, // Changed parameter to subject
    taskName: _taskNameController.text,
    description: _descriptionController.text,
    dueDate: _selectedDueDate!,
  );

  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Subject Dropdown
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value!;
                });
              },
              items: _subjects
                  .map((subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ))
                  .toList(),
              decoration: InputDecoration(labelText: "Select Subject"),
            ),

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
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

}
