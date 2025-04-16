import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_page.dart';
import '../services/firestore_service(users).dart';

class FollowersPage extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();
  final String userId;

  FollowersPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Followers")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));

          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: Text("No data found"));

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<String> followers = List<String>.from(userData['followers'] ?? []);

          return followers.isEmpty
              ? Center(child: Text("No followers yet"))
              : _buildFollowersList(followers, context);
        },
      ),
    );
  }

  Widget _buildFollowersList(List<String> followerIds, BuildContext context) {
    final List<String> limitedIds =
        followerIds.length > 10 ? followerIds.sublist(0, 10) : followerIds;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: limitedIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        if (snapshot.hasError)
          return Center(child: Text("Error loading followers"));

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Center(child: Text("No followers found"));

        var followers = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: followers.length,
          separatorBuilder: (_, __) => Divider(height: 10),
          itemBuilder: (context, index) {
            var followerData = followers[index].data() as Map<String, dynamic>? ?? {};
            String followerUserId = followers[index].id;
            String name = followerData['userName'] ?? 'Unknown';
            String email = followerData['email'] ?? '';
            String profileImage = followerData['profileImage'] ?? '';

            return ListTile(
              leading: FutureBuilder<String?>(
                future: firebaseService.getFollowerProfileImage(followerUserId, profileImage),
                builder: (context, snapshot) {
                  final imagePath = snapshot.data;
                  final hasImage = imagePath != null && File(imagePath).existsSync();

                  return CircleAvatar(
                    radius: 24,
                    backgroundImage: hasImage ? FileImage(File(imagePath!)) : null,
                    backgroundColor: Colors.grey[300],
                    child: !hasImage ? Icon(Icons.person, color: Colors.white) : null,
                  );
                },
              ),
              title: Text(name, style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(email),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilePage(userId: followerUserId)),
                );
              },
              trailing: userId == FirebaseAuth.instance.currentUser!.uid
                  ? TextButton.icon(
                      icon: Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                      label: Text("Remove", style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.08),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        firebaseService.removeFollower(userId, followerUserId);
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}

