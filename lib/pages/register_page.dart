import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/components/my_textfield.dart';
import 'package:study_planner/components/my_button.dart';
import 'package:study_planner/models/user_model.dart';
import 'package:study_planner/pages/botton_navigation.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list_page.dart'; // Import your Login Page here

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
        builder: (context) => const LoginPage(), // Ensure LoginPage exists
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              // Let's create an account for you
              Text(
                'Let\'s create an account for you',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              // Username textfield
              MyTextField(
                controller: userNameController,
                hintText: 'User Name',
                obsureText: false,
              ),

              const SizedBox(height: 10),

              // Email textfield
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obsureText: false,
              ),

              const SizedBox(height: 10),

              // Password textfield
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obsureText: true,
              ),

              const SizedBox(height: 10),

              // Confirm password textfield
              MyTextField(
                controller: confirmPasswordController,
                hintText: 'Confirm Password',
                obsureText: true,
              ),

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

                      // Create a UserModel instance
                      UserModel userModel = UserModel(
                        uid: uid,
                        userName: userNameController.text.trim(),
                        email: emailController.text.trim(),
                      );

                      // Add the user data to Firestore using the UID as the document ID
                      await ref.doc(uid).set(userModel.toMap());

                      print('User added successfully');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BottomNavigation(
                            homePage: HomePage(),
                            todoPage: TodoListPage(),
                            profilePage: ProfilePage(),
                          ), // Ensure LoginPage exists
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'weak-password') {
                        print('The password provided is too weak.');
                      } else if (e.code == 'email-already-in-use') {
                        print('The account already exists for that email.');
                      }
                    } catch (e) {
                      print("Error during registration: $e");
                    }
                  } else {
                    print('Password confirmation failed');
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
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: goToLoginPage,
                    child: const Text(
                      'Login now',
                      style: TextStyle(
                        color: Colors.blue,
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
}
