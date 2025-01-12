import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/pages/login_page.dart'; // Your login screen import here

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Study Planner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(), // Redirect to login page
    );
  }
}
