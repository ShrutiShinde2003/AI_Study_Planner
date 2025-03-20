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
  int xp = 0;
  String currentBadge = "Beginner";
  List<String> badges = ["Beginner", "Scholar", "Expert", "Master", "Legend"];
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    listenToCompletedTasks();
  }

  /// 🔹 Fetch user profile data from Firestore
  Future<void> fetchUserData() async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      if (userId.isEmpty) return;

      DocumentSnapshot snapshot =
          await _firestore.collection('users').doc(userId).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data() as Map<String, dynamic>;
          xp = userData!['xp'] ?? 0;
        });
      }
    } catch (e) {
      print("❌ Error fetching user data: $e");
    }
  }

  /// 🔥 Listen for real-time updates of completed tasks
  void listenToCompletedTasks() {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    _firestore.collection('users').doc(userId).snapshots().listen(
        (snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data()!;
        int updatedCompletedTasks = data['completedTasksCount'] ?? 0;
        int updatedXP = data['xp'] ?? 0;

        // 🔥 If all tasks are deleted, reset completedTasksCount AND XP
        QuerySnapshot taskSnapshot = await _firestore
            .collection('tasks')
            .where('uid', isEqualTo: userId)
            .get();
        if (taskSnapshot.docs.isEmpty) {
          updatedCompletedTasks = 0;
          updatedXP = 0; // ✅ Reset XP too
          await _firestore.collection('users').doc(userId).update({
            'completedTasksCount': 0,
            'xp': 0, // ✅ Reset XP to 0
          });
        }

        setState(() {
          completedTasks = updatedCompletedTasks;
          xp = updatedXP; // ✅ Update state with new XP value
          milestoneLevel = completedTasks ~/ 5;
          currentBadge = badges[(completedTasks ~/ 15) % badges.length];
        });

        print("🔥 Updated Tasks: completedTasks = $completedTasks, XP = $xp");
      } else {
        print("⚠️ No data found for user.");
      }
    }, onError: (error) {
      print("❌ Firestore listener error: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = (completedTasks % 5) / 5.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Home page"),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ Fix overflow issue
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWelcomeMessage(),
                SizedBox(height: 20),
                _buildXPProgress(),
                SizedBox(height: 20),
                _buildMilestoneProgress(progress),
                SizedBox(height: 20),
                _buildBadges(),
                SizedBox(height: 20),
                _buildCompletedTasks(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🏆 Welcome Message
  Widget _buildWelcomeMessage() {
    return userData == null
        ? Center(child: CircularProgressIndicator())
        : Center(
            child: Column(
              children: [
                Text(
                  'Welcome, ${userData!['userName']}!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
  }

  /// 🔥 XP & Level Progress Bar
  Widget _buildXPProgress() {
    return Column(
      children: [
        Text("💎 XP: $xp",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        LinearProgressIndicator(
          value: (xp % 100) / 100,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          minHeight: 8,
        ),
        SizedBox(height: 10),
        Text("Earn ${(100 - (xp % 100))} XP to level up!"),
      ],
    );
  }

  /// 🔥 Milestone Progress Section
  Widget _buildMilestoneProgress(double progress) {
    return Center(
      child: Column(
        children: [
          Text(
            "Milestone Level: $milestoneLevel",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  strokeWidth: 10,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Complete ${(5 - (completedTasks % 5))} more tasks to unlock the next milestone!",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  /// 🏅 Badges Section
  Widget _buildBadges() {
    return Center(
      child: Column(
        children: [
          Text("🏅 Current Badge",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
            child: Icon(Icons.emoji_events, size: 50, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(currentBadge,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text("Earn new badges every 15 tasks!",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  /// ✅ Completed Tasks Counter
  Widget _buildCompletedTasks() {
    return Center(
      child: Column(
        children: [
          Text("✅ Completed Tasks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(
            "$completedTasks Tasks Completed",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
