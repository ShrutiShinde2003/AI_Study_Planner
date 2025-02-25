import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_planner/pages/todo_list.dart';

class BottomNavigation extends StatefulWidget {
  final Widget homePage;
  final Widget dashboardPage;
  final Widget todoPage; // ✅ Add this back
  final Widget GeminiPage;
  final Widget profilePage;

  const BottomNavigation({
    required this.homePage,
    required this.dashboardPage,
       required this.todoPage, // ✅ Fix here
    required this.GeminiPage,
    required this.profilePage,
    Key? key,
  }) : super(key: key);

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchSubjects(); // 🔹 Fetch subjects when the app starts
  }

  // 🔹 Fetch subjects from Firestore every time To-Do List is opened
  void fetchSubjects() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        subjects = List<String>.from(
            (userDoc.data() as Map<String, dynamic>)['subjects'] ?? []);
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      fetchSubjects(); // 🔹 Fetch subjects when opening To-Do List
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      widget.homePage,
      ToDoListPage(subjects: subjects, subject: subjects.isNotEmpty ? subjects.first : ''),
      widget.dashboardPage,
      widget.GeminiPage,
      widget.profilePage,
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'ToDo'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
