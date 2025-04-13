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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade100, Colors.indigo.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTopSection(),
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

  Widget _buildTopSection() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade400, Colors.indigo.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Home",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 10),
            Text(
              'Hello, ${userData?['userName']}! 🎓',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 5),
            Text(
              "Let's stay on track with your study goals!",
              style:
                  TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  /// 💎 **XP Progress**
  Widget _buildXPProgress() {
    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("💎 XP: $xp",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: (xp % 100) / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 8,
          ),
          SizedBox(height: 10),
          Text("Earn ${(100 - (xp % 100))} XP to level up!",
              style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  /// 🎯 **Milestone Progress**
  Widget _buildMilestoneProgress(double progress) {
    return _buildGlassContainer(
      child: Column(
        children: [
          Text("🎯 Milestone Level: $milestoneLevel",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
          SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  strokeWidth: 10,
                ),
              ),
              Text(
                "${(progress * 100).toInt()}%",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            "Complete ${(5 - (completedTasks % 5))} more tasks to unlock the next milestone!",
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// 🏅 **Badges Section**
  Widget _buildBadges() {
    return _buildGlassContainer(
      child: Column(
        children: [
          Text("🏅 Current Badge",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(12),
            decoration:
                BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
            child: Icon(Icons.emoji_events, size: 50, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(currentBadge,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          SizedBox(height: 5),
          Text("Earn new badges every 15 tasks!",
              style: TextStyle(fontSize: 16, color: Colors.black54)),
        ],
      ),
    );
  }

  /// ✅ **Completed Tasks Counter**
  Widget _buildCompletedTasks() {
    return _buildGlassContainer(
      child: Column(
        children: [
          Text("✅ Completed Tasks",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple)),
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

  /// 📌 **Reusable Glassmorphism Container**
  Widget _buildGlassContainer({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}
