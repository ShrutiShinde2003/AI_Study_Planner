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

  String userName = "Loading...";
  String email = "Loading...";
  String profileImagePath = "";
  int followingCount = 0;
  int followersCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    if (widget.userId.isEmpty) return;

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        setState(() {
          userName = userData['userName'] ?? 'Unknown User';
          email = userData['email'] ?? 'No Email';
          profileImagePath = userData['profileImage'] ?? '';
          followersCount = (userData['followers'] as List?)?.length ?? 0;
          followingCount = (userData['following'] as List?)?.length ?? 0;
        });
      } else {
        setState(() {
          userName = "User Not Found";
          email = "No Email";
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> refreshProfile() async {
    fetchUserData();
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SettingsPage()));
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
                    stream: _firestore
                        .collection('users')
                        .doc(widget.userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data == null ||
                          !snapshot.data!.exists) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child:
                              Icon(Icons.person, size: 40, color: Colors.white),
                        );
                      }

                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>? ?? {};
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
                                builder: (context) => FollowersPage()));
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
                                builder: (context) => FollowingPage()));
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
                            builder: (context) => SearchUsersPage()));
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
