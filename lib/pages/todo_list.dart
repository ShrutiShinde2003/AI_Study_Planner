import 'package:flutter/material.dart';
import 'notes_page.dart'; // Import the Notes Page

class ToDoListPage extends StatefulWidget {
  final List<String> subjects; // Required subjects list

  ToDoListPage({required this.subjects, required String subject});

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("To-Do List")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Select a subject to add tasks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.subjects.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(widget.subjects[index]),
                    trailing: Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to Notes Page for task creation
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NotesPage(subject: widget.subjects[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
