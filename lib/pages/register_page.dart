import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/components/my_textfield.dart';
import 'package:study_planner/components/my_button.dart';
import 'package:study_planner/models/user_model.dart';
import 'package:study_planner/pages/botton_navigation.dart';
import 'package:study_planner/pages/dashboard.dart';
import 'package:study_planner/pages/gemini_ai.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list.dart'; // Import your Login Page here

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
              SizedBox(
                width: 350,
                child: TextField(
                  controller: userNameController,
                  obscureText: false,
                  decoration: InputDecoration(
                    hintText: 'User Name',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: BorderSide.none, // Default border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color for enabled state
                        width: 1, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.deepPurple, // Border color for focused state
                        width: 1, // Border width
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ), // Padding inside the text field
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Email textfield
              SizedBox(
                width: 350,
                child: TextField(
                  controller: emailController,
                  obscureText: false,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: BorderSide.none, // Default border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color for enabled state
                        width: 1, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.deepPurple, // Border color for focused state
                        width: 1, // Border width
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ), // Padding inside the text field
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Password textfield
              SizedBox(
                width: 350,
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: BorderSide.none, // Default border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color for enabled state
                        width: 1, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.deepPurple, // Border color for focused state
                        width: 1, // Border width
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ), // Padding inside the text field
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// Confirm Password textfield
              SizedBox(
                width: 350,
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: BorderSide.none, // Default border
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.black, // Border color for enabled state
                        width: 1, // Border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), // Corner radius
                      borderSide: const BorderSide(
                        color: Colors.deepPurple, // Border color for focused state
                        width: 1, // Border width
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 15,
                    ), // Padding inside the text field
                  ),
                ),
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
                        email: emailController.text.trim(), subjects: [],
                      );

                      // Add the user data to Firestore using the UID as the document ID
                      await ref.doc(uid).set(userModel.toMap());

                      // Feedback to the user and debug console
                      const successMessage = 'User added successfully';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(successMessage)),
                      );
                      print(successMessage);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BottomNavigation(
                            homePage: HomePage(),
                            todoPage: ToDoListPage(subjects: [], subject: '',),
                            dashboardPage: DashboardPage(),
                            profilePage: ProfilePage(userId: '',),
                            GeminiPage: ChatScreen(),
                          ), // Ensure LoginPage exists
                        ),
                      );
                    } on FirebaseAuthException catch (e) {
                      String errorMessage;
                      if (e.code == 'weak-password') {
                        errorMessage = 'The password provided is too weak.';
                      } else if (e.code == 'email-already-in-use') {
                        errorMessage =
                            'The account already exists for that email.';
                      } else {
                        errorMessage = 'Registration failed. Please try again.';
                      }
                      // Feedback to the user and debug console
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMessage)),
                      );
                      print(errorMessage);
                    } catch (e) {
                      const errorMessage =
                          'Error during registration. Please try again.';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(errorMessage)),
                      );
                      print("Error during registration: $e");
                    }
                  } else {
                    const errorMessage = 'Password confirmation failed.';
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(errorMessage)),
                    );
                    print(errorMessage);
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