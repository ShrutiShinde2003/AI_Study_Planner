import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchUsersPage extends StatefulWidget {
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
          .where('userName', isLessThanOrEqualTo: query + '\uf8ff')
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
    appBar: AppBar(
      title: Text("Search Users"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    backgroundColor: Colors.grey[100],
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            onChanged: searchUsers,
            decoration: InputDecoration(
              hintText: "Search by username or email",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: searchResults.length,
            separatorBuilder: (_, __) => SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = searchResults[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(user['userName'], style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(user['email'], style: TextStyle(color: Colors.grey[700])),
                  trailing: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) return SizedBox();

                      var currentUserData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                      List<dynamic> followingList = currentUserData['following'] ?? [];
                      bool isFollowing = followingList.contains(user.id);

                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing ? Colors.grey[300] : Colors.blueAccent,
                          foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () {
                          isFollowing ? unfollowUser(user.id) : followUser(user.id);
                        },
                        child: Text(isFollowing ? "Unfollow" : "Follow"),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}
}