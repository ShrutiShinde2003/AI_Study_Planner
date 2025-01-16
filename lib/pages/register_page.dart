// Flutter and Dart Registration Page with Firebase Integration
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? _errorMessage;

  Future<void> _register() async {
  setState(() {
    _errorMessage = null;
  });

  // Input validation
  if (_nameController.text.trim().isEmpty) {
    setState(() {
      _errorMessage = 'Full Name cannot be empty.';
    });
    return;
  }

  if (_emailController.text.trim().isEmpty) {
    setState(() {
      _errorMessage = 'Email cannot be empty.';
    });
    return;
  }

  if (!_emailController.text.trim().contains('@')) {
    setState(() {
      _errorMessage = 'Invalid email format.';
    });
    return;
  }

  if (_passwordController.text.trim().isEmpty) {
    setState(() {
      _errorMessage = 'Password cannot be empty.';
    });
    return;
  }

  if (_passwordController.text.trim().length < 6) {
    setState(() {
      _errorMessage = 'Password must be at least 6 characters long.';
    });
    return;
  }

  try {
    // Create user with email and password
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Save user details to Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'uid': userCredential.user!.uid,
      'createdAt': DateTime.now().toIso8601String(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registration successful!')),
    );

    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
  } catch (e) {
    setState(() {
      _errorMessage = e.toString();
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
