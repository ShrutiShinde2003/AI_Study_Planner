import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_planner/pages/todo_list_page.dart';  // Import the ToDo page

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            onPressed: () async {
              // Call the sign-out method from AuthService
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the user object to access displayName and email
            Text(
              'Welcome, ${user?.displayName ?? 'User'}\n${user?.email}',
              style: const TextStyle(fontSize: 18.0),
            ),
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
