import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo_list.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  ProfilePage({required this.userId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _subjectController = TextEditingController();

  String userName = "";
  String email = "";
  String profileImagePath = "";
  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
    loadProfileImage();
    fetchSubjects();
  }

  // 🔹 Fetch User Data (Name & Email)
  void fetchUserData() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists) {
      setState(() {
        userName = userDoc['userName'] ?? 'No Name';
        email = userDoc['email'] ?? 'No Email';
      });
    }
  }

  // 🔹 Fetch Subjects from Firestore
  void fetchSubjects() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();

    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        subjects = List<String>.from((userDoc.data() as Map<String, dynamic>)['subjects'] ?? []);
      });
    }
  }

  // 🔹 Add Subject to Firestore
  void _addSubject() async {
    String userId = _auth.currentUser!.uid;
    String subject = _subjectController.text.trim();

    if (subject.isNotEmpty) {
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'subjects': FieldValue.arrayUnion([subject])
      });

      _subjectController.clear();
      fetchSubjects(); // Refresh the list
    }
  }

  // 🔹 Delete Subject & Its Tasks
  void _deleteSubject(String subject) async {
    String userId = _auth.currentUser!.uid;

    try {
      // Delete tasks related to this subject
      QuerySnapshot tasksSnapshot = await _firestore
          .collection('tasks')
          .where('uid', isEqualTo: userId)
          .where('subjectName', isEqualTo: subject)
          .get();

      for (var doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      // Remove subject from user's list
      DocumentReference userDoc = _firestore.collection('users').doc(userId);
      await userDoc.update({
        'subjects': FieldValue.arrayRemove([subject])
      });

      fetchSubjects(); // Refresh list
    } catch (e) {
      print("❌ Error deleting subject: $e");
    }
  }

  // 🔹 Show Avatar & Gallery Upload Options
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Male Avatar"),
              onTap: () => _setLocalAvatar("assets/male_avatar.png"),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text("Female Avatar"),
              onTap: () => _setLocalAvatar("assets/female_avatar.png"),
            ),
            ListTile(
              leading: Icon(Icons.photo),
              title: Text("Upload from Gallery"),
              onTap: _pickImageFromGallery,
            ),
          ],
        );
      },
    );
  }

  // 🔹 Set Local Avatar
  void _setLocalAvatar(String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', imagePath);
    setState(() {
      profileImagePath = imagePath;
    });
    Navigator.pop(context);
  }

  // 🔹 Pick Image from Gallery
  Future<void> _pickImageFromGallery() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _saveImageLocally(imageFile);
    }
  }

  // 🔹 Save Image in Local Storage
  Future<void> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final localImagePath = '${directory.path}/profile_image.jpg';

    await imageFile.copy(localImagePath);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', localImagePath);

    setState(() {
      profileImagePath = localImagePath;
    });
  }

  // 🔹 Load Profile Image from Storage
  Future<void> loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      profileImagePath = prefs.getString('profileImagePath') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Image
            GestureDetector(
              onTap: _showImagePicker,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: profileImagePath.isNotEmpty
                    ? (profileImagePath.contains("assets/")
                        ? AssetImage(profileImagePath) as ImageProvider
                        : FileImage(File(profileImagePath)))
                    : null,
                child: profileImagePath.isEmpty
                    ? Icon(Icons.add, size: 40, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 10),

            // User Info
            Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),

            // Subject Input Field
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: "Add Subject",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addSubject,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Subjects List
            Expanded(
              child: subjects.isEmpty
                  ? Center(child: Text("No subjects added yet"))
                  : ListView.builder(
                      itemCount: subjects.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(subjects[index]),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteSubject(subjects[index]),
                          ),
                        );
                      },
                    ),
            ),
            SizedBox(height: 20),

            // To-Do List Button
            ElevatedButton(
              onPressed: () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;
                DocumentSnapshot userDoc =
                    await FirebaseFirestore.instance.collection('users').doc(userId).get();
                List<String> subjects = List<String>.from(userDoc['subjects'] ?? []);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToDoListPage(
                      subjects: subjects,
                      subject: subjects.isNotEmpty ? subjects[0] : '',
                    ),
                  ),
                );
              },
              child: Text("Go to To-Do List"),
            ),
          ],
        ),
      ),
    );
  }
}
