import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import '../services/firestore_service(users).dart';

class FollowingPage extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();
  final String userId;

  FollowingPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Following")),
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
          List<String> following = List<String>.from(userData['following'] ?? []);

          if (following.isEmpty) {
            return Center(child: Text("You're not following anyone"));
          }

          return _buildFollowingList(following, context);
        },
      ),
    );
  }

  Widget _buildFollowingList(List<String> followingIds, BuildContext context) {
    if (followingIds.isEmpty) {
      return Center(child: Text("Not following anyone yet."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId,
              whereIn: followingIds.length > 10 ? followingIds.sublist(0, 10) : followingIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading following list"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No following found"));
        }

        var followingList = snapshot.data!.docs;

        return ListView.builder(
          itemCount: followingList.length,
          itemBuilder: (context, index) {
            var followingData = followingList[index].data() as Map<String, dynamic>? ?? {};
            String followingUserId = followingList[index].id;
            String name = followingData['userName'] ?? 'Unknown';
            String profileImage = followingData['profileImage'] ?? '';

            return ListTile(
              leading: FutureBuilder<String?>(
                future: firebaseService.getFollowingProfileImage(followingUserId, profileImage),
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
                    backgroundImage: imageExists ? FileImage(File(imagePath!)) : null,
                    child: !imageExists ? Icon(Icons.person, color: Colors.white) : null,
                    backgroundColor: Colors.grey[300],
                  );
                },
              ),
              title: Text(name),
              subtitle: Text(followingData['email'] ?? ""),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(userId: followingUserId)),
                );
              },
              trailing: userId == FirebaseAuth.instance.currentUser!.uid
                  ? ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({
                          'following': FieldValue.arrayRemove([followingUserId])
                        });

                        await FirebaseFirestore.instance.collection('users').doc(followingUserId).update({
                          'followers': FieldValue.arrayRemove([userId])
                        });
                      },
                      child: Text("Unfollow"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
