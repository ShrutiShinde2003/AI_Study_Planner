import 'package:flutter/material.dart';

class BottomNavigation extends StatefulWidget {
  final Widget homePage;
  final Widget todoPage;
  final Widget dashboardPage;
  final Widget GeminiPage;
  final Widget profilePage;

  const BottomNavigation({
    required this.homePage,
    required this.todoPage,
    required this.dashboardPage,
    required this.GeminiPage,
    required this.profilePage,
    Key? key,
  }) : super(key: key);

  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      widget.homePage,
      widget.todoPage,
      widget.dashboardPage,
      widget.GeminiPage,
      widget.profilePage,
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue, // Color for the selected icon
        unselectedItemColor: Colors.grey, // Color for unselected icons
        backgroundColor: Colors.white, // Background color of the bar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'ToDo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
