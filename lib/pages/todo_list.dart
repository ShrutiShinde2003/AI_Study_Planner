import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/task_card.dart';
import 'notes_page.dart';
import 'package:intl/intl.dart';

class ToDoListPage extends StatefulWidget {
  ToDoListPage();

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _subjects = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 🔹 Fetch subjects from Firestore
  Future<void> _fetchSubjects() async {
    final user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists && userDoc.data() != null) {
      List<String> subjects = List<String>.from(userDoc['subjects'] ?? []);
      setState(() {
        _subjects = subjects;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To-Do List"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Past Due"),
            Tab(text: "Completed"),
            Tab(text: "Forthcoming"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTaskList(filterType: "past_due"),
          _buildTaskList(filterType: "completed"),
          _buildTaskList(filterType: "forthcoming"),
        ],
      ),

      // ✅ Floating Action Button to Open Notes Page
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotesPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskList({required String filterType}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _subjects.isNotEmpty
          ? _firestore
              .collection('tasks')
              .where('uid', isEqualTo: _auth.currentUser?.uid)
              .where('subject', whereIn: _subjects) // 🔹 Filter only existing subjects
              .orderBy('dueDate', descending: false)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        var tasks = snapshot.data!.docs.where((taskDoc) {
          var taskData = taskDoc.data() as Map<String, dynamic>;
          bool isCompleted = taskData['isCompleted'] ?? false;
          DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
          DateTime now = DateTime.now();

          if (filterType == "past_due") {
            return dueDate != null && dueDate.isBefore(now) && !isCompleted;
          } else if (filterType == "completed") {
            return isCompleted;
          } else if (filterType == "forthcoming") {
            return dueDate != null && dueDate.isAfter(now) && !isCompleted;
          }
          return false;
        }).toList();

        if (tasks.isEmpty) return Center(child: Text("No tasks available"));

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var taskDoc = tasks[index];
            var taskData = taskDoc.data() as Map<String, dynamic>;

            DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
            String formattedDate = dueDate != null
                ? DateFormat('dd MMM yyyy, hh:mm a').format(dueDate)
                : 'No Due Date';

            return Dismissible(
              key: Key(taskDoc.id),
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) async {
                await _firestore.collection('tasks').doc(taskDoc.id).delete();
                setState(() {});
              },
              child: TaskCard(
                taskId: taskDoc.id,
                taskData: {...taskData, 'dueDate': formattedDate},
              ),
            );
          },
        );
      },
    );
  }
}