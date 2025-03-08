import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'search_users_page.dart';
import 'followers_page.dart';
import 'following_page.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userName = "";
  String email = "";
  String profileImagePath = "";
  int followingCount = 0;
  int followersCount = 0;
  List<String> subjects = [];
  TextEditingController _subjectController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchSubjects();
  }

  void fetchUserData() async {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (userId.isEmpty) return;

  DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();

  if (userDoc.exists) {
    setState(() {
      userName = userDoc['userName'] ?? 'No Name';
      email = userDoc['email'] ?? 'No Email';
    });

    // Fetch followers separately
    FirebaseFirestore.instance
        .collection('users')
        .where('following', arrayContains: userId) // Find users who follow me
        .get()
        .then((followersSnapshot) {
      setState(() {
        followersCount = followersSnapshot.docs.length;
      });
    });

    // Fetch following separately
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get()
        .then((userSnapshot) {
      List<dynamic> followingList = userSnapshot['following'] ?? [];
      setState(() {
        followingCount = followingList.length;
      });
    });
  }
}



  void fetchSubjects() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists && userDoc.data() != null) {
      List<dynamic> subjectsData = userDoc['subjects'] ?? [];
      setState(() {
        subjects = subjectsData.cast<String>();
      });
    }
  }

  void addSubject() async {
    String newSubject = _subjectController.text.trim();
    if (newSubject.isEmpty) return;

    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    await userDocRef.update({
      'subjects': FieldValue.arrayUnion([newSubject])
    });

    setState(() {
      subjects.add(newSubject);
    });

    _subjectController.clear();
  }

  void deleteSubject(String subject) async {
    bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Are you sure?"),
        content: Text(
            "Deleting this subject will remove all related tasks permanently."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == null || !confirmDelete) return;

    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    setState(() {
      subjects.remove(subject);
    });

    DocumentReference userDocRef = _firestore.collection('users').doc(userId);

    await userDocRef.update({
      'subjects': FieldValue.arrayRemove([subject])
    });

    QuerySnapshot tasksSnapshot = await _firestore
        .collection('tasks')
        .where('userId', isEqualTo: userId)
        .where('subject', isEqualTo: subject)
        .get();

    for (QueryDocumentSnapshot taskDoc in tasksSnapshot.docs) {
      await _firestore.collection('tasks').doc(taskDoc.id).delete();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Subject and all related tasks deleted")),
    );
  }

Future<void> refreshProfile() async {
  fetchUserData(); // Refresh user data
  fetchSubjects(); // Refresh subjects list
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    String? updatedImage = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfilePage()),
                    );
                    if (updatedImage != null) {
                      setState(() {
                        profileImagePath = updatedImage;
                      });
                    }
                  },
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser!.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          child:
                              Icon(Icons.person, size: 40, color: Colors.white),
                        );
                      }
        
                      var userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      String imageUrl = userData['profileImage'] ?? '';
        
                      return CircleAvatar(
                        radius: 50,
                        backgroundImage: imageUrl.isNotEmpty
                            ? (imageUrl.contains("assets/")
                                ? AssetImage(imageUrl) as ImageProvider
                                : FileImage(File(imageUrl)))
                            : null,
                        child: imageUrl.isEmpty
                            ? Icon(Icons.person, size: 40, color: Colors.white)
                            : null,
                      );
                    },
                  ),
                ),
                SizedBox(height: 10),
                Text(userName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 20),
        
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FollowersPage()),
                        );
                      },
                      child: Column(
                        children: [
                          Text(followersCount.toString(),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Followers", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                    SizedBox(width: 40),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FollowingPage()),
                        );
                      },
                      child: Column(
                        children: [
                          Text(followingCount.toString(),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Following", style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
        
                SizedBox(height: 20),
        
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SearchUsersPage()),
                    );
                  },
                  child: Text("Add Friends"),
                ),
        
                SizedBox(height: 20),
        
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Subjects:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                subjects.isEmpty
                    ? Text("No subjects added", style: TextStyle(color: Colors.grey))
                    : Column(
                        children: subjects.map((subject) {
                          return ListTile(
                            leading: Icon(Icons.book, color: Colors.blue),
                            title: Text(subject, style: TextStyle(fontSize: 16)),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteSubject(subject),
                            ),
                          );
                        }).toList(),
                      ),
                TextField(
                  controller: _subjectController,
                  decoration: InputDecoration(labelText: "Add Subject"),
                ),
                ElevatedButton(
                  onPressed: addSubject,
                  child: Text("Add Subject"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}