import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'search_users_page.dart';
import 'followers_page.dart';
import 'following_page.dart';
import '../services/gamification_service.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GamificationService _gamificationService = GamificationService();

  UserModel? user;
  bool isCurrentUser = false;
  List<UserModel> recommendedUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (widget.userId.isEmpty) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(widget.userId).get();

    if (userDoc.exists) {
      setState(() {
        user = UserModel.fromDocumentSnapshot(userDoc);
        isCurrentUser = widget.userId == _auth.currentUser?.uid;
      });
      fetchRecommendedUsers();
    }
  }

  /// **🔹 Fetch Recommended Users Based on Common Subjects**
  Future<void> fetchRecommendedUsers() async {
    if (user == null || user!.subjects.isEmpty) return;

    QuerySnapshot querySnapshot = await _firestore.collection('users').get();

    List<UserModel> allUsers = querySnapshot.docs
        .map((doc) => UserModel.fromDocumentSnapshot(doc))
        .where((u) => u.uid != user!.uid) // Exclude current user
        .toList();

    List<UserModel> filteredUsers = allUsers.where((u) {
      return u.subjects.any((subject) => user!.subjects.contains(subject));
    }).toList();

    setState(() {
      recommendedUsers = filteredUsers.take(5).toList();
    });
  }

  Future<void> refreshProfile() async {
    fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isCurrentUser ? "My Profile" : "Profile"),
        actions: isCurrentUser
            ? [
                IconButton(
                  icon: Icon(Icons.settings, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    );
                  },
                ),
              ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: refreshProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildProfileHeader(),
                SizedBox(height: 20),
                _buildFollowSection(),
                SizedBox(height: 20),
                isCurrentUser ? _buildAddFriendsButton() : Container(),
                SizedBox(height: 30),
                _buildGamificationProgress(),
                SizedBox(height: 30),
                _buildRecommendations(), // 🔹 Added Profile Recommendations Section
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        _buildProfileImage(),
        SizedBox(height: 10),
        Text(user?.userName ?? "No Name",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(user?.email ?? "No Email",
            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildUserCard(UserModel user) {
  return ListTile(
    leading: CircleAvatar(
      backgroundImage: user.profileImage.isNotEmpty
          ? NetworkImage(user.profileImage)
          : AssetImage("assets/default_avatar.png") as ImageProvider,
    ),
    title: Text(user.userName),
    subtitle: Text(user.email),
    trailing: ElevatedButton(
      onPressed: () {
        _firestore.collection('users').doc(widget.userId).update({
          'following': FieldValue.arrayUnion([user.uid])
        });
      },
      child: Text("Follow"),
    ),
  );
}

  Widget _buildProfileImage() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(widget.userId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String imageUrl = userData['profileImage'] ?? '';

        return CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: imageUrl.isNotEmpty
              ? (imageUrl.startsWith('http') ||
                      imageUrl.startsWith('assets/')
                  ? NetworkImage(imageUrl) as ImageProvider
                  : FileImage(File(imageUrl)))
              : null,
          child: imageUrl.isEmpty
              ? Icon(Icons.person, size: 50, color: Colors.white)
              : null,
        );
      },
    );
  }

  Widget _buildFollowSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _followStat("Followers", user?.followers.length ?? 0, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FollowersPage(userId: widget.userId)),
          );
        }),
        SizedBox(width: 40),
        _followStat("Following", user?.following.length ?? 0, () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => FollowingPage(userId: widget.userId)),
          );
        }),
      ],
    );
  }

  Widget _followStat(String title, int count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(count.toString(),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildAddFriendsButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: Colors.blueAccent,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchUsersPage()),
        );
      },
      child: Text("Add Friends",
          style: TextStyle(fontSize: 18, color: Colors.white)),
    );
  }

  Widget _buildGamificationProgress() {
    if (user == null) return CircularProgressIndicator();

    double xpProgress = (user!.xp % 100) / 100.0;
    double milestoneProgress = (user!.taskProgress % 5) / 5.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _progressCircle("XP", user!.xp, xpProgress, Colors.blue),
        _progressCircle("🔥 Streak", user!.streak, 1.0, Colors.orange),
        _progressCircle("🎯 Tasks", user!.taskProgress, milestoneProgress, Colors.green),
      ],
    );
  }

  /// **✅ Merged `_progressCircle` Method**
  Widget _progressCircle(String title, int value, double progress, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 7,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text("$value",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  /// **✅ Merged `_buildRecommendations` Method**
  Widget _buildRecommendations() {
  if (recommendedUsers.isEmpty) return SizedBox();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("People You May Know",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SizedBox(height: 10),
      Column(
        children: recommendedUsers
            .map<Widget>((user) => _buildUserCard(user)) // Explicitly specify `Widget`
            .toList(),
      ),
    ],
  );
}

}
