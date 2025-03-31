import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/services/firestore_service(users).dart';

class FollowersPage extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

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

          return _buildFollowersList(followers);
        },
      ),
    );
  }

  Widget _buildFollowersList(List<String> followerIds) {
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

            return ListTile(
              leading: FutureBuilder<String?>(
                future: firebaseService.getFollowerProfileImage(followerUserId, followerData['profileImage']), // FIXED
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.white),
                    );
                  }

                  String? imagePath = snapshot.data;
                  bool imageExists = imagePath != null && File(imagePath).existsSync();

                  print("Follower: $followerUserId -> Image Path: $imagePath | Exists: $imageExists");

                  return CircleAvatar(
                    backgroundImage: imageExists ? FileImage(File(imagePath!)) : null,
                    child: !imageExists ? Icon(Icons.person, color: Colors.white) : null,
                    backgroundColor: Colors.grey[300],
                  );
                },
              ),
              title: Text(followerData['userName'] ?? "Unknown"),
              subtitle: Text(followerData['email'] ?? ""),
              trailing: ElevatedButton(
                onPressed: () {
                  firebaseService.removeFollower(
                      FirebaseAuth.instance.currentUser!.uid, followerUserId);
                },
                child: Text("Remove"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
