import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/user_model.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:study_planner/services/auth_service.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/register_page.dart'; // Import HomePage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final auth = FirebaseAuth.instance;

  // Future<void> _login() async {
  //   try {
  //     // Attempt login
  //     // PigeonUserDetails? userDetails = await _authService.login(
  //     //   _emailController.text,
  //     //   _passwordController.text,
  //     // );

  //     // // If login is successful, navigate to HomePage with userDetails
  //     // if (userDetails != null) {
  //     //   Navigator.pushReplacement(
  //     //     context,
  //     //     MaterialPageRoute(
  //     //       builder: (context) => HomePage(userDetails: userDetails),
  //     //     ),
  //     //   );

  //     auth
  //         .signInWithEmailAndPassword(
  //       email: _emailController.text,
  //       password: _passwordController.text,
  //     )
  //         .then((value) {
  //       Navigator.pushAndRemoveUntil(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => HomePage(),
  //         ),
  //         (Route<dynamic> route) => false,
  //       );

  //       // add this toast later
  //       // Fluttertoast.showToast(
  //       //   msg: 'Logged In Successfully!',
  //       //   toastLength: Toast.LENGTH_SHORT,
  //       //   gravity: ToastGravity.BOTTOM,
  //       //   backgroundColor: Colors.green,
  //       //   textColor: Colors.white,
  //       // );
  //     }).catchError((error) {
  //       Navigator.pop(context); // Dismiss the loading indicator

  //       // this also
  //       // Fluttertoast.showToast(
  //       //   msg: 'Please Verify your credentials',
  //       //   toastLength: Toast.LENGTH_SHORT,
  //       //   gravity: ToastGravity.BOTTOM,
  //       //   backgroundColor: const Color.fromARGB(255, 240, 91, 91),
  //       //   textColor: const Color.fromARGB(255, 255, 255, 255),
  //       // );
  //     });
  //   } catch (e) {
  //     print(e.toString());
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text(e.toString())));
  //   }
  // }

  Future<void> _login() async {
    try {
      UserCredential userCredential = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Navigate to HomePage and pass userModel
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
