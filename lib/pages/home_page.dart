import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/pages/login_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int completedTasks = 0;
  int milestoneLevel = 0;
  String currentBadge = "Beginner"; // Default badge
  List<String> badges = ["Beginner", "Scholar", "Expert", "Master"];
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    listenToCompletedTasks(); // 🔥 Real-time updates from Firestore
  }

  /// 🔹 Fetch user profile data from Firestore
  Future<void> fetchUserData() async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      DocumentSnapshot snapshot = await _firestore.collection('users').doc(userId).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  /// 🔥 **Listen to Completed Tasks Count from Firestore**
  void listenToCompletedTasks() {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    _firestore.collection('users').doc(userId).snapshots().listen((snapshot) async {
      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data();
        int updatedCompletedTasks = data?['completedTasksCount'] ?? -1; // 🔍 Default to -1 if missing

        if (updatedCompletedTasks == -1) {
          print("⚠️ completedTasksCount field missing! Initializing...");
          await _firestore.collection('users').doc(userId).update({'completedTasksCount': 0});
          return;
        }

        setState(() {
          completedTasks = updatedCompletedTasks;
          milestoneLevel = completedTasks ~/ 5; // 🔥 Every 5 tasks = 1 Milestone
          currentBadge = badges[(completedTasks ~/ 15) % badges.length]; // 🔥 Every 15 tasks = New Badge
        });

        print("🔥 Firestore Updated: completedTasksCount = $completedTasks");
      }
    }, onError: (error) {
      print("❌ Firestore listener error: $error");
    });
  }

  /// 🔹 Sign user out
  void signUserOut(BuildContext context) {
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (completedTasks % 5) / 5.0; // 🔥 Progress bar fills every 5 tasks

    return Scaffold(
      appBar: AppBar(
        title: Text("Study Progress"),
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false, // Removes back button
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => signUserOut(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Welcome Message
            if (userData != null)
              Center(
                child: Column(
                  children: [
                    Text(
                      'Welcome, ${userData!['userName']}!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text('Email: ${userData!['email']}'),
                  ],
                ),
              ),

            SizedBox(height: 30),

            // 🔥 Current Milestone
            Center(
              child: Column(
                children: [
                  Text(
                    "Milestone Level: $milestoneLevel",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 10,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Complete ${(5 - (completedTasks % 5))} more tasks to unlock next milestone!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // 🏆 Badges Section
            Center(
              child: Column(
                children: [
                  Text(
                    "Current Badge",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    currentBadge,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Earn new badges every 15 tasks!",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // ✅ Completed Tasks Count
            Center(
              child: Column(
                children: [
                  Text(
                    "Completed Tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "$completedTasks Tasks Completed",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
