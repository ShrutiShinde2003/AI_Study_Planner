import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import '../services/firestore_service(users).dart';

class FollowersPage extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();
  final String userId;

  FollowersPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Followers")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("No data found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<String> followers = List<String>.from(userData['followers'] ?? []);

          if (followers.isEmpty) {
            return Center(child: Text("No followers yet"));
          }

          return _buildFollowersList(followers, context);
        },
      ),
    );
  }

  Widget _buildFollowersList(List<String> followerIds, BuildContext context) {
    if (followerIds.isEmpty) {
      return Center(child: Text("No followers yet"));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId,
              whereIn: followerIds.length > 10 ? followerIds.sublist(0, 10) : followerIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading followers"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No followers found"));
        }

        var followers = snapshot.data!.docs;

        return ListView.builder(
          itemCount: followers.length,
          itemBuilder: (context, index) {
            var followerData = followers[index].data() as Map<String, dynamic>? ?? {};
            String followerUserId = followers[index].id;
            String name = followerData['userName'] ?? 'Unknown';
            String profileImage = followerData['profileImage'] ?? '';

            return ListTile(
              leading: FutureBuilder<String?>(
                future: firebaseService.getFollowerProfileImage(followerUserId, profileImage),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }

                  String? imagePath = snapshot.data;
                  bool imageExists = imagePath != null && File(imagePath).existsSync();

                  return CircleAvatar(
                    backgroundImage: imageExists ? FileImage(File(imagePath)) : null,
                    backgroundColor: Colors.grey[300],
                    child: !imageExists ? Icon(Icons.person, color: Colors.white) : null,
                  );
                },
              ),
              title: Text(name),
              subtitle: Text(followerData['email'] ?? ""),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(userId: followerUserId)),
                );
              },
              trailing: userId == FirebaseAuth.instance.currentUser!.uid
                  ? ElevatedButton(
                      onPressed: () {
                        firebaseService.removeFollower(userId, followerUserId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text("Remove"),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
