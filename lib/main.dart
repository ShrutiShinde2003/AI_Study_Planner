import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/forgot_password.dart';
import 'package:study_planner/pages/register_page.dart';
import 'package:study_planner/pages/home_page.dart'; 
import 'package:study_planner/pages/todo_list_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Authentication App', 
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/', 
      routes: {
        '/': (context) => const LoginPage(),
        '/forgot_password': (context) => const ForgotPasswordPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}