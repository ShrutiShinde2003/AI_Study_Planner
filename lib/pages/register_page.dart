import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:study_planner/components/my_button.dart';
import 'package:study_planner/models/user_model.dart';
import 'package:study_planner/pages/bottom_navigation.dart';
import 'package:study_planner/pages/dashboard.dart';
import 'package:study_planner/pages/gemini_ai.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final userNameController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  CollectionReference ref = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  bool passwordConfirmed() {
    return passwordController.text.trim() == confirmPasswordController.text.trim();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String> _saveImageLocally(String uid) async {
    if (_image == null) return "";
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = "${directory.path}/profile_$uid.jpg";
    final File localImage = await _image!.copy(imagePath);
    return localImage.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade200,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile Image Selection
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: _image != null ? FileImage(_image!) : null,
                          child: _image == null
                              ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                              : null,
                        ),
                        if (_image != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.indigo.shade200,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.edit, size: 20, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Let\'s create an account for you',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  // User Name Field
                  _buildTextField(userNameController, "User Name"),
                  const SizedBox(height: 10),

                  // Email Field
                  _buildTextField(emailController, "Email"),
                  const SizedBox(height: 10),

                  // Password Field
                  _buildTextField(passwordController, "Password", isObscure: true),
                  const SizedBox(height: 10),

                  // Confirm Password Field
                  _buildTextField(confirmPasswordController, "Confirm Password", isObscure: true),
                  const SizedBox(height: 25),

                  // Sign Up Button
                  MyButton(
                    text: 'Sign Up',
                    onTap: () async {
                      if (passwordConfirmed()) {
                        try {
                          final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                            email: emailController.text.trim(),
                            password: passwordController.text.trim(),
                          );
                          final user = credential.user!;
                          var uid = user.uid;
                          String imagePath = await _saveImageLocally(uid);
                          UserModel userModel = UserModel(
                            uid: uid,
                            userName: userNameController.text.trim(),
                            email: emailController.text.trim(),
                            subjects: [],
                            followers: [],
                            following: [],
                            profileImage: imagePath,
                          );
                          await ref.doc(uid).set(userModel.toMap());
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString("profileImage_$uid", imagePath);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('User added successfully')));
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BottomNavigation(
                                homePage: HomePage(),
                                todoPage: ToDoListPage(),
                                dashboardPage: DashboardPage(),
                                profilePage: ProfilePage(userId: uid),
                                GeminiPage: ChatScreen(),
                              ),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Error during registration. Please try again.')));
                        }
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Passwords do not match!')));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Text Field Widget
  Widget _buildTextField(TextEditingController controller, String hint, {bool isObscure = false}) {
    return SizedBox(
      width: 370,
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
