import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_planner/pages/todo_list.dart';
import 'package:study_planner/pages/chat_page.dart'; // 🔹 Import Chat Page

class BottomNavigation extends StatefulWidget {
  final Widget homePage;
  final Widget dashboardPage;
  final Widget todoPage;
  final Widget GeminiPage;
  final Widget profilePage;

  const BottomNavigation({
    required this.homePage,
    required this.dashboardPage,
    required this.todoPage,
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
    fetchSubjects(); // 🔹 Fetch subjects when app starts
  }

  // 🔹 Fetch subjects from Firestore
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
      fetchSubjects(); // 🔹 Refresh subjects when To-Do List is opened
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      widget.homePage,
      ToDoListPage(),
      widget.dashboardPage,
      ChatPage(), // Add Chat Page
      widget.GeminiPage,
      widget.profilePage,
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 28,
        selectedItemColor: Colors.blue, // Make selected icon visible
        unselectedItemColor: Colors.grey, // Keep unselected icons visible
        enableFeedback: false, // Disable default ripple effect
        backgroundColor: Colors.white, // Ensure visibility on dark background
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
        selectedIconTheme:
            IconThemeData(size: 30), // Optional: Slightly larger selected icon
      ),
    );
  }
}
