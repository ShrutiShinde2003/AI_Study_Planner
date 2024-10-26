import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Ensure you have this model
import 'package:study_planner/pages/home_page.dart';
import 'package:study_planner/pages/login_page.dart';
import 'package:study_planner/services/pigeon_user_details.dart'; // Ensure you have the LoginPage

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
      title: 'AI Study Planner',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            // Check if user is logged in
            User? user = snapshot.data;
            if (user != null) {
              // If user is logged in, show HomePage
              return HomePage(
                userDetails: PigeonUserDetails(
                  uid: user.uid,
                  email: user.email,
                ), // Pass user details
              );
            } else {
              // If user is not logged in, show LoginPage
              return const LoginPage();
            }
          } else {
            // While waiting for the connection to be established
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// class HomePage extends StatelessWidget {
//   final PigeonUserDetails? userDetails; // Make userDetails nullable

//   const HomePage({super.key, this.userDetails});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home Page'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () async {
//               await FirebaseAuth.instance.signOut(); // Sign out from Firebase
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Text(
//           userDetails != null
//               ? 'Welcome, ${userDetails!.userName}!'
//               : 'Welcome to your Study Planner!', // Default message if userDetails is null
//         ),
//       ),
//     );
//   }
// }

// Ensure you have the PigeonUserDetails model properly defined
// The userName extension can be integrated into the model directly, ensure your model has a userName property.
// class PigeonUserDetails {
//   final String userName;

//   PigeonUserDetails({required this.userName});
// }
