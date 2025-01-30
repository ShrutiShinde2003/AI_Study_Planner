import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/components/my_button.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/todo_list.dart'; // Import TodoListPage

class HomePage extends StatelessWidget {
   HomePage({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  CollectionReference ref = FirebaseFirestore.instance.collection('users');

  // Sign user out method
  void signUserOut(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  // Fetch user data
  Future<Map<String, dynamic>> fetchUserData() async {
    try {
      DocumentSnapshot snapshot = await ref.doc(user.uid).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        throw Exception("User document does not exist");
      }
    } catch (e) {
      throw Exception("Failed to fetch user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () => signUserOut(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          final userData = snapshot.data!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome, ${userData['userName']}!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Email: ${userData['email']}'),
                SizedBox(height: 20),
                MyButton(
                  onTap: () {
                    // Navigate to ToDo page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodoListPage(),
                      ),
                    );
                  },
                  text: 'Go to ToDo List',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}