import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ✅ Import Firebase Messaging
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // ✅ For Local Notifications
import 'package:study_planner/pages/bottom_navigation.dart';
import 'package:study_planner/pages/gemini_ai.dart';
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/pages/profile_page.dart';
import 'package:study_planner/pages/todo_list.dart';
import 'package:study_planner/pages/dashboard.dart';
import 'package:study_planner/pages/start_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔹 Background Notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
  }

  /// ✅ Setup Firebase Messaging
  void _setupFirebaseMessaging() async {
    // Request permissions for notifications (iOS)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🔔 Notification Permission: ${settings.authorizationStatus}');

    // ✅ Handle Foreground Notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔴 Foreground Notification: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // ✅ Handle Notification Click (when the app is in background but open)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🟡 Opened Notification: ${message.notification?.title}");
    });

    // ✅ Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// ✅ Show Local Notification when in Foreground
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'group_chat_channel',
      'Group Chat Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          String userId = snapshot.data!.uid;
          return BottomNavigation(
            homePage: HomePage(),
            todoPage: ToDoListPage(),
            dashboardPage: DashboardPage(),
            GeminiPage: ChatScreen(),
            profilePage: ProfilePage(userId: userId),
          );
        } else {
          return const WelcomePage();
        }
      },
    );
  }
}
