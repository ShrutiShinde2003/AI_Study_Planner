import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text("Following")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: CircularProgressIndicator());
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          List<dynamic> following = userData['following'] ?? [];

          return following.isEmpty
              ? Center(child: Text("You're not following anyone"))
              : ListView.builder(
                  itemCount: following.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(following[index]).get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData || userSnapshot.data == null) {
                          return ListTile(title: Text("Loading..."));
                        }

                        var followingData = userSnapshot.data!.data() as Map<String, dynamic>;
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
                                'following': FieldValue.arrayRemove([following[index]])
                              });

                              await FirebaseFirestore.instance.collection('users').doc(following[index]).update({
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
