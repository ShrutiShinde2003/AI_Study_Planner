import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
          List<dynamic> followers = userData['followers'] ?? [];

          if (followers.isEmpty) {
            return Center(child: Text("No followers yet"));
          }

          return ListView.builder(
            itemCount: followers.length,
            itemBuilder: (context, index) {
              String followerUserId = followers[index] ?? ''; // Ensure it's a valid string
              if (followerUserId.isEmpty) {
                return SizedBox(); // Skip empty user IDs
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(followerUserId).get(),
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

                  var followerData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: followerData['profileImage'] != null
                          ? NetworkImage(followerData['profileImage'])
                          : null,
                      child: followerData['profileImage'] == null ? Icon(Icons.person) : null,
                    ),
                    title: Text(followerData['userName'] ?? "Unknown"),
                    subtitle: Text(followerData['email'] ?? ""),
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