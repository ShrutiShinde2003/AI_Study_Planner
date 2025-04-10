import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchUsersPage extends StatefulWidget {
  const SearchUsersPage({super.key});

  @override
  _SearchUsersPageState createState() => _SearchUsersPageState();
}

class _SearchUsersPageState extends State<SearchUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> searchResults = [];

  void searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      QuerySnapshot userNameResults = await firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      QuerySnapshot emailResults = await firestore
          .collection('users')
          .where('email', isEqualTo: query)
          .get();

      Set<String> seenUserIds = {};
      List<DocumentSnapshot> allResults = [];

      for (var doc in [...userNameResults.docs, ...emailResults.docs]) {
        if (!seenUserIds.contains(doc.id)) {
          seenUserIds.add(doc.id);
          allResults.add(doc);
        }
      }

      setState(() {
        searchResults = allResults;
      });
    } catch (e) {
      print("❌ Error searching users: $e");
    }
  }

  void followUser(String targetUserId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentReference userRef = firestore.collection('users').doc(userId);
    DocumentReference targetUserRef = firestore.collection('users').doc(targetUserId);

    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        DocumentSnapshot targetUserSnapshot = await transaction.get(targetUserRef);

        if (!userSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception("User does not exist");
        }

        transaction.update(userRef, {
          'following': FieldValue.arrayUnion([targetUserId])
        });

        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayUnion([userId])
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Followed user")),
      );

      setState(() {}); // Refresh UI
    } catch (e) {
      print("❌ Error following user: $e");
    }
  }

  void unfollowUser(String targetUserId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    DocumentReference userRef = firestore.collection('users').doc(userId);
    DocumentReference targetUserRef = firestore.collection('users').doc(targetUserId);

    try {
      await firestore.runTransaction((transaction) async {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        DocumentSnapshot targetUserSnapshot = await transaction.get(targetUserRef);

        if (!userSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception("User does not exist");
        }

        transaction.update(userRef, {
          'following': FieldValue.arrayRemove([targetUserId])
        });

        transaction.update(targetUserRef, {
          'followers': FieldValue.arrayRemove([userId])
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unfollowed user")),
      );

      setState(() {}); // Refresh UI
    } catch (e) {
      print("❌ Error unfollowing user: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Users")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: searchUsers,
              decoration: InputDecoration(
                labelText: "Search by Username or Email",
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: searchResults.map((user) {
                return ListTile(
                  title: Text(user['userName']),
                  subtitle: Text(user['email']),
                  trailing: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return SizedBox();
                      }

                      var currentUserData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      List<dynamic> followingList = currentUserData['following'] ?? [];

                      bool isFollowing = followingList.contains(user.id);

                      return ElevatedButton(
                        onPressed: () {
                          if (isFollowing) {
                            unfollowUser(user.id);
                          } else {
                            followUser(user.id);
                          }
                        },
                        child: Text(isFollowing ? "Unfollow" : "Follow"),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
