import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/task_card.dart';
import 'notes_page.dart';
import 'package:intl/intl.dart';
import '../services/gamification_service.dart'; // Import Gamification Service

class ToDoListPage extends StatefulWidget {
  ToDoListPage();

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService = GamificationService(); // Initialize service

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

  /// Fetch subjects from Firestore
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => NotesPage()));
        },
        child: Icon(Icons.add),
      ),
    );
  }

  /// 🔥 Task List Builder
  Widget _buildTaskList({required String filterType}) {
    final user = _auth.currentUser;
    if (user == null) return Center(child: Text("User not authenticated"));

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tasks')
          .where('uid', isEqualTo: user.uid)
          .where('subject', whereIn: _subjects.isNotEmpty ? _subjects : ['dummy']) // Fix empty subject case
          .orderBy('dueDate', descending: false) // Use indexed order
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No tasks available"));

        DateTime now = DateTime.now();
        var tasks = snapshot.data!.docs.where((taskDoc) {
          var data = taskDoc.data() as Map<String, dynamic>;
          bool isCompleted = data['isCompleted'] ?? false;
          DateTime? dueDate = (data['dueDate'] as Timestamp?)?.toDate();

          if (filterType == "past_due") return dueDate != null && dueDate.isBefore(now) && !isCompleted;
          if (filterType == "completed") return isCompleted;
          if (filterType == "forthcoming") return dueDate != null && dueDate.isAfter(now) && !isCompleted;
          return false;
        }).toList();

        if (tasks.isEmpty) return Center(child: Text("No tasks in this category"));

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            var taskDoc = tasks[index];
            var taskData = taskDoc.data() as Map<String, dynamic>;
            DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
            String formattedDate = dueDate != null ? DateFormat('dd MMM yyyy, hh:mm a').format(dueDate) : 'No Due Date';

            return TaskCard(
              taskId: taskDoc.id,
              taskData: {...taskData, 'dueDate': formattedDate},
              onCompleteTask: () async {
                await _toggleTaskCompletion(taskDoc.id, taskData['isCompleted'] ?? false);
                _updateCompletedTasksCount();
              },
            );
          },
        );
      },
    );
  }

  /// 🔥 Toggle task completion (Mark complete/uncomplete + XP & Rewards)
  Future<void> _toggleTaskCompletion(String taskId, bool isCurrentlyCompleted) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'isCompleted': !isCurrentlyCompleted,
        'completedAt': !isCurrentlyCompleted ? FieldValue.serverTimestamp() : null,
      });

      // Update XP & progress only when marking as completed
      if (!isCurrentlyCompleted) {
        await _gamificationService.updateUserProgress();
      }

      print("✅ Task completion toggled: ${!isCurrentlyCompleted}");
    } catch (e) {
      print("❌ Error toggling task completion: $e");
    }
  }

  /// Update completed tasks count for homepage
  Future<void> _updateCompletedTasksCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot completedTasks = await _firestore
          .collection('tasks')
          .where('uid', isEqualTo: user.uid)
          .where('isCompleted', isEqualTo: true)
          .get();

      int completedCount = completedTasks.docs.length;
      await _firestore.collection('users').doc(user.uid).update({'completedTasksCount': completedCount});
      print("✅ Completed tasks count updated: $completedCount");
    } catch (e) {
      print("❌ Error updating completed task count: $e");
    }
  }
}
