import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  await _scheduleDueDateNotifications(); // 🔔 Schedule Task Notifications
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

// ✅ Moved _showNotification outside to make it globally accessible
void _showNotification(String title, String body) {
  _localNotifications.show(
    0,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'channel_id',
        'Task Reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
  );
}

// 🔔 Schedule task notifications based on due date
Future<void> _scheduleDueDateNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  FirebaseFirestore.instance
      .collection('tasks')
      .where('uid', isEqualTo: user.uid)
      .where('isCompleted', isEqualTo: false)
      .snapshots()
      .listen((snapshot) async {
    for (var taskDoc in snapshot.docs) {
      var taskData = taskDoc.data();
      DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
      String taskName = taskData['taskName'] ?? "Task";

      if (dueDate != null) {
        DateTime now = DateTime.now();
        Duration timeUntilDue = dueDate.difference(now);

        // Notify user 8 hour before the task is due
        if (timeUntilDue.inHours == 8 && timeUntilDue.inMinutes > 0) {
          _showNotification("Upcoming Task", "$taskName is due in 8 hours.");
        }

        // Notify user 5 Hours before the task is due
        if (timeUntilDue.inHours == 5 && timeUntilDue.inMinutes > 0) {
          _showNotification("Reminder", "$taskName is due in 5 hours.");
        }

        // Notify user 1 hour before the task is due
        if (timeUntilDue.inHours == 1 && timeUntilDue.inMinutes > 0) {
          _showNotification("Reminder", "$taskName is due in 1 hour.");
        }
      }
    }
  });
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