import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowersPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Followers")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> followers = userData['followers'] ?? [];

          return followers.isEmpty
              ? Center(child: Text("No followers yet"))
              : ListView.builder(
                  itemCount: followers.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(followers[index]).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || userSnapshot.data == null) {
                          return ListTile(title: Text("Loading..."));
                        }

                        var followerData = userSnapshot.data!.data() as Map<String, dynamic>;
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
