// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:study_planner/services/auth_service.dart';
import 'package:study_planner/services/pigeon_user_details.dart';
import 'package:study_planner/pages/todo_list_page.dart';

class HomePage extends StatelessWidget {
  final AuthService _authService = AuthService();
  final PigeonUserDetails userDetails;

  HomePage({super.key, required this.userDetails});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, ${userDetails.displayName ?? userDetails.email}'),
            const SizedBox(height: 20),
            // Button to navigate to the To-Do List page
            ElevatedButton(
              onPressed: () {
                // Navigate to the To-Do List page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TodoListPage()),
                );
              },
              child: const Text('Go to To-Do List'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on AuthService {
  void logout() {}
}
