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
      // 🔹 Search by username (case-insensitive)
      QuerySnapshot userNameResults = await firestore
          .collection('users')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // 🔹 Search by email (exact match)
      QuerySnapshot emailResults = await firestore
          .collection('users')
          .where('email', isEqualTo: query)
          .get();

      // 🔹 Merge results (avoid duplicates)
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

  void addFriend(String friendId) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('users').doc(userId).update({
        'following': FieldValue.arrayUnion([friendId])
      });

      await firestore.collection('users').doc(friendId).update({
        'followers': FieldValue.arrayUnion([userId])
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Friend Added!")),
      );
    } catch (e) {
      print("❌ Error adding friend: $e");
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
                  trailing: ElevatedButton(
                    onPressed: () => addFriend(user.id),
                    child: Text("Add"),
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
