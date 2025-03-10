import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'search_users_page.dart';
import 'followers_page.dart';
import 'following_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "";
  String email = "";
  String profileImagePath = "";
  int followingCount = 0;
  int followersCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        userName = userDoc['userName'] ?? 'No Name';
        email = userDoc['email'] ?? 'No Email';

        // ✅ Get followers count directly from Firestore
        List<dynamic> followersList = userDoc['followers'] ?? [];
        followersCount = followersList.length;

        // ✅ Get following count directly from Firestore
        List<dynamic> followingList = userDoc['following'] ?? [];
        followingCount = followingList.length;
      });
    }
  }

  Future<void> refreshProfile() async {
    fetchUserData(); // Refresh user data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
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
                GestureDetector(
                  onTap: () async {
                    String? updatedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EditProfilePage()),
                    );
                    if (updatedImage != null) {
                      setState(() {
                        profileImagePath = updatedImage;
                      });
                    }
                  },
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child:
                              Icon(Icons.person, size: 40, color: Colors.white),
                        );
                      }

                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String imageUrl = userData['profileImage'] ?? '';

                      return CircleAvatar(
                        radius: 50,
                        backgroundImage: imageUrl.isNotEmpty
                            ? (imageUrl.contains("assets/")
                                ? AssetImage(imageUrl) as ImageProvider
                                : FileImage(File(imageUrl)))
                            : null,
                        child: imageUrl.isEmpty
                            ? Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Text(userName,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FollowersPage()),
                        );
                      },
                      child: Column(
                        children: [
                          Text(followersCount.toString(),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Followers", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(width: 40),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FollowingPage()),
                        );
                      },
                      child: Column(
                        children: [
                          Text(followingCount.toString(),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Following", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchUsersPage()),
                    );
                  },
                  child: Text("Add Friends"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
