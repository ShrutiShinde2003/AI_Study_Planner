import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/components/my_button.dart';
import 'package:study_planner/models/user_model.dart';
import 'package:study_planner/pages/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Controllers for text fields
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final userNameController = TextEditingController();

  final CollectionReference ref =
      FirebaseFirestore.instance.collection('users');

  bool _isRegistering = false; // Prevent multiple clicks

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    userNameController.dispose();
    super.dispose();
  }

  // Check if passwords match
  bool passwordConfirmed() {
    return passwordController.text.trim() ==
        confirmPasswordController.text.trim();
  }

  // Register User
  Future<void> registerUser() async {
    if (_isRegistering) return; // Prevent multiple clicks
    setState(() {
      _isRegistering = true;
    });

    if (!passwordConfirmed()) {
      showSnackBar('Passwords do not match!', Colors.red);
      setState(() {
        _isRegistering = false;
      });
      return;
    }

    try {
      // Step 1: Create user with email and password
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = credential.user!;
      final uid = user.uid;

      // Step 2: Store user data in Firestore
      UserModel userModel = UserModel(
        uid: uid,
        userName: userNameController.text.trim(),
        email: emailController.text.trim(),
        subjects: [],
        followers: [],
        following: [],
        profileImage: "",
      );

      await ref.doc(uid).set(userModel.toMap());

      // Step 3: Success message
      showSnackBar('User created successfully! Please login.', Colors.green);

      // Step 4: Navigate to Login Page after delay
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for this email.';
      } else {
        errorMessage = 'Registration failed. Please try again.';
      }
      showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      showSnackBar('Error during registration. Please try again.', Colors.red);
    }

    // Reset button state
    setState(() {
      _isRegistering = false;
    });
  }

  // Show a SnackBar with a message
  void showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade200,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Text(
                'Let\'s create an account for you',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              inputField(
                  controller: userNameController,
                  hintText: 'User Name',
                  obscureText: false),
              const SizedBox(height: 10),
              inputField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false),
              const SizedBox(height: 10),
              inputField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true),
              const SizedBox(height: 10),
              inputField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true),
              const SizedBox(height: 25),
              MyButton(
                text: _isRegistering ? 'Registering...' : 'Sign Up',
                onTap: _isRegistering ? null : registerUser,
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already a member?',
                      style: TextStyle(color: Colors.indigo)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      'Login now',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget inputField(
      {required TextEditingController controller,
      required String hintText,
      required bool obscureText}) {
    return SizedBox(
      width: 370,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
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
          contentPadding:
              const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        ),
      ),
    );
  }
}
