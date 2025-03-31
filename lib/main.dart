import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:study_planner/pages/bottom_navigation.dart';
import 'package:study_planner/pages/gemini_ai.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list.dart';
import 'package:study_planner/pages/dashboard.dart';
import 'package:study_planner/pages/start_page.dart';

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await _setupFirebaseMessaging();

  runApp(MyApp());
}

Future<void> _setupFirebaseMessaging() async {
  // Request permissions for notifications
  NotificationSettings settings = await _firebaseMessaging.requestPermission();
  print("User granted permission: ${settings.authorizationStatus}");

  // Initialize local notifications
  const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
  await _localNotifications.initialize(initSettings);

  // Handle background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // Handle user authentication
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _setupForegroundNotificationListener();
  }

  void _setupForegroundNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        _showNotification(notification.title ?? "New Message", notification.body ?? "");
      }
    });
  }

  void _showNotification(String title, String body) {
    _localNotifications.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Chat Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen for auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          String userId = snapshot.data!.uid; // Get logged-in user's ID
          return BottomNavigation(
            homePage: HomePage(),
            todoPage: ToDoListPage(),
            dashboardPage: DashboardPage(),
            GeminiPage: ChatScreen(),
            profilePage: ProfilePage(userId: userId),
          );
        } else {
          return const WelcomePage(); // Show login page if no user is signed in
        }
      },
    );
  }
}