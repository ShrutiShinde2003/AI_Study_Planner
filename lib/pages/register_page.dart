import 'package:flutter/material.dart';
import 'package:study_planner/models/user_model.dart';
// import 'package:study_planner/services/auth_service.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:study_planner/services/pigeon_user_details.dart'; // Import PigeonUserDetails

import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // final AuthService _authService = AuthService();

  final auth = FirebaseAuth.instance;

  CollectionReference collectionReference =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'User Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  // Future<void> _register() async {
  //   try {
  //     // Attempt to register the user
  //     await auth
  //         .createUserWithEmailAndPassword(
  //       email: _emailController.text.trim(),
  //       password: _passwordController.text.trim(),
  //     )
  //         .then((value) {
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => HomePage(),
  //         ),
  //         (Route<dynamic> route) => false,
  //       );
  //     });

  //     // Add this for showing a toast on success (optional)
  //     // Fluttertoast.showToast(
  //     //   msg: 'Registration successful!',
  //     //   toastLength: Toast.LENGTH_SHORT,
  //     //   gravity: ToastGravity.BOTTOM,
  //     //   backgroundColor: Colors.green,
  //     //   textColor: Colors.white,
  //     // );
  //   } catch (e) {
  //     print('Error: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Registration failed: ${e.toString()}')),
  //     );

  //     // Uncomment this for showing a toast on failure (optional)
  //     // Fluttertoast.showToast(
  //     //   msg: 'Registration failed. Please try again.',
  //     //   toastLength: Toast.LENGTH_SHORT,
  //     //   gravity: ToastGravity.BOTTOM,
  //     //   backgroundColor: const Color.fromARGB(255, 240, 91, 91),
  //     //   textColor: const Color.fromARGB(255, 255, 255, 255),
  //     // );
  //   }
  // }

  Future<void> _register() async {
    try {
      print('before auth');
      await auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          )
          .then((value) => add_user(context));

      // print('after auth');

      // User? firebaseUser = auth.currentUser;

      // if (firebaseUser != null) {
      //   // Create a UserModel instance from Firebase user details
      //   UserModel userModel = UserModel(
      //     uid: firebaseUser.uid,
      //     userName: firebaseUser.email?.split('@').first ?? 'User',
      //     email: firebaseUser.email!,
      //   );

      // print('inside if');

      // Navigate to HomePage and pass userModel
      // Navigator.pushAndRemoveUntil(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => HomePage(userModel: userModel),
      //   ),
      //   (Route<dynamic> route) => false,
      // );
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${e.toString()}')),
      );
    }
  }

  add_user(context) async {
    // add logic

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      UserModel userModel = UserModel(
        uid: user.uid,
        userName: _usernameController.text.trim(),
        email: user.email!,
      );

      Map<String, dynamic> userMap = userModel.toMap();

      await collectionReference
          .doc(auth.currentUser?.uid)
          .set(userMap)
          .then((value) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (Route<dynamic> route) => false,
        );
      });
    }
  }
}
