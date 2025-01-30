import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/pages/botton_navigation.dart';
import 'package:study_planner/pages/gemini_ai.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list.dart';
import 'package:study_planner/pages/dashboard.dart';
import 'package:study_planner/pages/start_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if a user is signed in
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: user != null
          ? BottomNavigation(
              homePage: HomePage(),
              todoPage: TodoListPage(),
              dashboardPage: DashboardPage(),
              GeminiPage: ChatScreen(),
              profilePage: ProfilePage(),
              
            )
          : const WelcomePage(), // Replace with your actual login page
    );
  }
}