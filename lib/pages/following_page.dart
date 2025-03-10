import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/services/firestore_service(users).dart';

class FollowingPage extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

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
          List<dynamic> following = userData['following'] ?? [];

          if (following.isEmpty) {
            return Center(child: Text("You're not following anyone"));
          }

          return ListView.builder(
            itemCount: following.length,
            itemBuilder: (context, index) {
              String followingUserId = following[index] ?? '';
              if (followingUserId.isEmpty) {
                return SizedBox(); // Skip empty user IDs
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(followingUserId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(title: Text("Loading..."));
                  }

                  if (userSnapshot.hasError) {
                    return ListTile(title: Text("Error loading user"));
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return ListTile(
                      title: Text("User not found"),
                      subtitle: Text("This user may have deleted their account"),
                      leading: Icon(Icons.error, color: Colors.red),
                    );
                  }

                  var followingData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  return ListTile(
                    leading: FutureBuilder<String?>(
                      future: firebaseService.getFollowingProfileImage(followingUserId, followingData['profileImage']), // ✅ FIXED
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircleAvatar(
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, color: Colors.white),
                          );
                        }

                        String? imagePath = snapshot.data;
                        bool imageExists = imagePath != null && File(imagePath).existsSync();

                        print("Following: $followingUserId -> Image Path: $imagePath | Exists: $imageExists");

                        return CircleAvatar(
                          backgroundImage: imageExists ? FileImage(File(imagePath!)) : null,
                          child: !imageExists ? Icon(Icons.person, color: Colors.white) : null,
                          backgroundColor: Colors.grey[300],
                        );
                      },
                    ),
                    title: Text(followingData['userName'] ?? "Unknown"),
                    subtitle: Text(followingData['email'] ?? ""),
                    trailing: ElevatedButton(
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
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}