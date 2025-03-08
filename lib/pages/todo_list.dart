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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔹 Fetch subjects from Firestore
  Future<void> _fetchSubjects() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        List<String> subjects = List<String>.from(userDoc['subjects'] ?? []);
        setState(() {
          _subjects = subjects;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("❌ Error fetching subjects: $e");
      setState(() => isLoading = false);
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _subjects.isEmpty
              ? Center(child: Text("No subjects available. Please add subjects."))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskList(filterType: "past_due"),
                    _buildTaskList(filterType: "completed"),
                    _buildTaskList(filterType: "forthcoming"),
                  ],
                ),
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
  if (_subjects.isEmpty) {
    return Center(child: Text("No subjects available."));
  }

  return StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('tasks')
        .where('uid', isEqualTo: _auth.currentUser?.uid)
        .where('subject', whereIn: _subjects.isNotEmpty ? _subjects : ['dummy']) // ✅ Fix for Firestore `whereIn` issue
        .snapshots(), // 🔥 Removed `orderBy('dueDate')` for debugging
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        print("ℹ️ No tasks found for filter: $filterType");
        return Center(child: Text("No tasks available"));
      }

      var now = DateTime.now();
      var tasks = snapshot.data!.docs.where((taskDoc) {
        var taskData = taskDoc.data() as Map<String, dynamic>;
        bool isCompleted = taskData['isCompleted'] ?? false;
        DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();

        print("🔍 Task: ${taskData['taskName']}, Due: ${dueDate?.toString()}");

        if (filterType == "past_due") {
          return dueDate != null && dueDate.isBefore(now) && !isCompleted;
        } else if (filterType == "completed") {
          return isCompleted;
        } else if (filterType == "forthcoming") {
          return dueDate != null && dueDate.isAfter(now) && !isCompleted;
        }
        return false;
      }).toList();

      if (tasks.isEmpty) {
        print("ℹ️ Tasks filtered out for category: $filterType");
        return Center(child: Text("No tasks in this category"));
      }

      return ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          var taskDoc = tasks[index];
          var taskData = taskDoc.data() as Map<String, dynamic>;

          DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
          String formattedDate = dueDate != null
              ? DateFormat('dd MMM yyyy, hh:mm a').format(dueDate)
              : 'No Due Date';

          return TaskCard(
            taskId: taskDoc.id,
            taskData: {...taskData, 'dueDate': formattedDate},
            onCompleteTask: () async {
              await completeTask(taskDoc.id);
              _updateCompletedTasksCount();
            },
            onDeleteTask: () async {
              await deleteTask(taskDoc.id, taskData['isCompleted'] ?? false, taskData);
              _updateCompletedTasksCount();
            },
          );
        },
      );
    },
  );
}


  /// 🔥 Mark task as completed
  Future<void> completeTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Error completing task: $e");
    }
  }

  /// 🗑️ Delete task and move to completedTasks if needed
  Future<void> deleteTask(String taskId, bool isCompleted, Map<String, dynamic> taskData) async {
    try {
      if (isCompleted) {
        await _firestore.collection('completedTasks').doc(taskId).set(taskData);
      }
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      print("❌ Error deleting task: $e");
    }
  }

  /// ✅ Update Completed Tasks Count in Firestore (for HomePage)
  Future<void> _updateCompletedTasksCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot completedTasksSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .where('isCompleted', isEqualTo: true)
          .get();

      int completedCount = completedTasksSnapshot.docs.length;

      await _firestore.collection('users').doc(user.uid).update({
        'completedTasksCount': completedCount,
      });

      print("✅ Updated completed tasks count: $completedCount");
    } catch (e) {
      print("❌ Error updating completed tasks count: $e");
    }
  }
}
