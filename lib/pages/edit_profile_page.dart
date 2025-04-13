import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String profileImagePath = "";

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  /// 🔹 Load user data from Firestore & SharedPreferences
  void loadUserData() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(userId).get();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _nameController.text = userDoc['userName'] ?? '';
      _emailController.text = userDoc['email'] ?? '';
      profileImagePath = prefs.getString('profileImage_$userId') ??
          userDoc['profileImage'] ??
          '';
    });

    print("🔍 Loaded Image for $userId: $profileImagePath");
  }

  /// 🔹 Show Avatar & Gallery Upload Options
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text("Male Avatar"),
              onTap: () => _setLocalAvatar("lib/assets/images/male_avatar.png"),
            ),
            ListTile(
              leading: Icon(Icons.person_outline),
              title: Text("Female Avatar"),
              onTap: () =>
                  _setLocalAvatar("lib/assets/images/female_avatar.png"),
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

  /// 🔹 Set Local Avatar
  void _setLocalAvatar(String imagePath) async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    await saveUserProfileImagePath(userId, imagePath);

    setState(() {
      profileImagePath = imagePath;
    });

    _updateProfileImage(imagePath);
    Navigator.pop(context);
  }

  /// 🔹 Pick Image from Gallery
  Future<void> _pickImageFromGallery() async {
    Navigator.pop(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      _saveImageLocally(imageFile);
    }
  }

  /// 🔹 Save Image in Local Storage and SharedPreferences
  Future<void> _saveImageLocally(File imageFile) async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final directory = await getApplicationDocumentsDirectory();
    final localImagePath = '${directory.path}/profile_$userId.jpg';

    await imageFile.copy(localImagePath);
    await saveUserProfileImagePath(userId, localImagePath);

    setState(() {
      profileImagePath = localImagePath;
    });

    _updateProfileImage(localImagePath);
  }

  /// Save Image Path in SharedPreferences per user
  Future<void> saveUserProfileImagePath(String userId, String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImage_$userId', imagePath);
    print(" Saved Image for $userId: $imagePath");
  }

  /// 🔹 Update Profile Image in Firestore
  void _updateProfileImage(String imagePath) async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    await _firestore.collection('users').doc(userId).update({
      'profileImage': imagePath,
    });

    print(" Firestore Updated Image Path: $imagePath");
  }

  /// 🔹 Save Updated User Profile
  void saveProfile() async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        'userName': _nameController.text,
        'email': _emailController.text,
      });

      if (_passwordController.text.isNotEmpty) {
        User? user = _auth.currentUser;

        String? currentPassword = await showDialog<String>(
          context: context,
          builder: (context) {
            TextEditingController passwordController = TextEditingController();
            return AlertDialog(
              title: Text("Enter Current Password"),
              content: TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(hintText: "Current Password"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text("Cancel"),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, passwordController.text),
                  child: Text("Confirm"),
                ),
              ],
            );
          },
        );

        if (currentPassword == null || currentPassword.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password update canceled")),
          );
          return;
        }

        AuthCredential credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_passwordController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password updated successfully!")),
        );
      }

      Navigator.pop(context, profileImagePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating profile: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Profile")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: profileImagePath.isNotEmpty
                      ? (profileImagePath.contains("assets/")
                          ? AssetImage(profileImagePath) as ImageProvider
                          : FileImage(File(profileImagePath)))
                      : null,
                  child: profileImagePath.isEmpty
                      ? Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                GestureDetector(
                  onTap: _showImagePicker,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Name")),
            TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email")),
            TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "New Password"),
                obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: saveProfile, child: Text("Save")),
          ],
        ),
      ),
    );
  }
}