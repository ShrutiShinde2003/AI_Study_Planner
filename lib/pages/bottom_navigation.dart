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
      ChatPage(),
      widget.GeminiPage,
      widget.profilePage,
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            iconSize: 26,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).unselectedWidgetColor,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIconTheme: IconThemeData(size: 28),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.check_circle_rounded), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: ''),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: ''),
            ],
          ),
        ),
      ),
    );
  }
}
