import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/components/my_button.dart';
import 'package:study_planner/models/user_model.dart';
import 'package:study_planner/pages/bottom_navigation.dart';
import 'package:study_planner/pages/dashboard.dart';
import 'package:study_planner/pages/gemini_ai.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text editing controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final userNameController = TextEditingController();

  // Firestore reference
  CollectionReference ref = FirebaseFirestore.instance.collection('users');

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  // Password confirmation logic
  bool passwordConfirmed() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  // Navigate to Login Page
  void goToLoginPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade200, // Background color
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Text(
                'Let\'s create an account for you',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // Username textfield
              _buildTextField(userNameController, 'User Name'),
              const SizedBox(height: 10),

              // Email textfield
              _buildTextField(emailController, 'Email'),
              const SizedBox(height: 10),

              // Password textfield
              _buildTextField(passwordController, 'Password', isPassword: true),
              const SizedBox(height: 10),

              // Confirm Password textfield
              _buildTextField(confirmPasswordController, 'Confirm Password', isPassword: true),
              const SizedBox(height: 25),

              // Sign up button
              MyButton(
                text: 'Sign Up',
                onTap: () async {
                  if (passwordConfirmed()) {
                    try {
                      final credential = await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      // Get the UID of the newly created user
                      final user = credential.user!;
                      var uid = user.uid;

                      // ✅ Create a UserModel instance with `completedTasksCount: 0`
                      UserModel userModel = UserModel(
                        uid: uid,
                        userName: userNameController.text.trim(),
                        email: emailController.text.trim(),
                        subjects: [], // Default empty subject list
                        completedTasksCount: 0, // ✅ Ensure completedTasksCount is initialized
                      );

                      // ✅ Add the user data to Firestore
                      await ref.doc(uid).set(userModel.toMap());

                      // ✅ Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User added successfully')),
                      );

                      // ✅ Navigate to the Bottom Navigation Page
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
                    } on FirebaseAuthException catch (e) {
                      _showErrorMessage(e.code);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error during registration. Please try again.')),
                      );
                      print("Error during registration: $e");
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password confirmation failed.')),
                    );
                  }
                },
              ),

              const SizedBox(height: 50),

              // Already a member? Login here
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already a member?',
                    style: TextStyle(color: Colors.indigo),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: goToLoginPage,
                    child: const Text(
                      'Login now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Reusable method for building text fields
  Widget _buildTextField(TextEditingController controller, String hintText, {bool isPassword = false}) {
    return SizedBox(
      width: 370,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }

  /// 🔹 Show FirebaseAuth error messages
  void _showErrorMessage(String errorCode) {
    String errorMessage;
    if (errorCode == 'weak-password') {
      errorMessage = 'The password provided is too weak.';
    } else if (errorCode == 'email-already-in-use') {
      errorMessage = 'The account already exists for that email.';
    } else {
      errorMessage = 'Registration failed. Please try again.';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
  }
}
