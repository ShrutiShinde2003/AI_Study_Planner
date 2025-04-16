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
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));

          if (!snapshot.hasData || !snapshot.data!.exists)
            return Center(child: Text("No data found"));

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          List<String> following = List<String>.from(userData['following'] ?? []);

          return following.isEmpty
              ? Center(child: Text("You're not following anyone"))
              : _buildFollowingList(following, context);
        },
      ),
    );
  }

  Widget _buildFollowingList(List<String> followingIds, BuildContext context) {
    final limitedIds = followingIds.length > 10 ? followingIds.sublist(0, 10) : followingIds;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: limitedIds)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        if (snapshot.hasError)
          return Center(child: Text("Error loading following list"));

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return Center(child: Text("No following found"));

        var followingList = snapshot.data!.docs;

        return ListView.separated(
          padding: EdgeInsets.all(12),
          itemCount: followingList.length,
          separatorBuilder: (_, __) => Divider(height: 10),
          itemBuilder: (context, index) {
            var followingData = followingList[index].data() as Map<String, dynamic>? ?? {};
            String followingUserId = followingList[index].id;
            String name = followingData['userName'] ?? 'Unknown';
            String email = followingData['email'] ?? '';
            String profileImage = followingData['profileImage'] ?? '';

            return ListTile(
              leading: FutureBuilder<String?>(
                future: firebaseService.getFollowingProfileImage(followingUserId, profileImage),
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
                  MaterialPageRoute(builder: (_) => ProfilePage(userId: followingUserId)),
                );
              },
              trailing: userId == FirebaseAuth.instance.currentUser!.uid
                  ? TextButton.icon(
                      icon: Icon(Icons.person_remove_alt_1_outlined, size: 18, color: Colors.red),
                      label: Text("Unfollow", style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.08),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({
                          'following': FieldValue.arrayRemove([followingUserId])
                        });

                        await FirebaseFirestore.instance.collection('users').doc(followingUserId).update({
                          'followers': FieldValue.arrayRemove([userId])
                        });
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

