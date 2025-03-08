import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

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
              String followingUserId = following[index] ?? ''; // Ensure it's a valid string
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
                    leading: CircleAvatar(
                      backgroundImage: followingData['profileImage'] != null
                          ? NetworkImage(followingData['profileImage'])
                          : null,
                      child: followingData['profileImage'] == null ? Icon(Icons.person) : null,
                    ),
                    title: Text(followingData['userName'] ?? "Unknown"),
                    subtitle: Text(followingData['email'] ?? ""),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(userId).update({
                          'following': FieldValue.arrayRemove([followingUserId])
                        });

                        await FirebaseFirestore.instance.collection('users').doc(followingUserId).update({
                          'followers': FieldValue.arrayRemove([userId])
                        });
                      },
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