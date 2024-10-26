// // lib/pages/home_page.dart

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:study_planner/models/user_model.dart';
// import 'package:study_planner/services/auth_service.dart';
// import 'package:study_planner/pages/todo_list_page.dart';

// FirebaseAuth auth = FirebaseAuth.instance;
// final userId = auth.currentUser?.uid;

// class HomePage extends StatelessWidget {
//   // final AuthService _authService = AuthService();
//   // final UserModel user;
//   HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Home Page'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.logout),
//             onPressed: () {
//               // _authService.logout();
//               Navigator.pushReplacementNamed(context, '/login');
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Welcome'),
//             const SizedBox(height: 20),
//             // Button to navigate to the To-Do List page
//             ElevatedButton(
//               onPressed: () {
//                 // Navigate to the To-Do List page
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => TodoListPage()),
//                 );
//               },
//               child: const Text('Go to To-Do List'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // extension on AuthService {
// //   void logout() {}
// // }

// start
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:study_planner/models/user_model.dart';

class HomePage extends StatelessWidget {
  final UserModel? userModel;

  const HomePage({super.key, this.userModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Center(
        child: Text(
          userModel != null
              ? 'Welcome, ${userModel!.userName}!'
              : 'Welcome to your Study Planner!',
        ),
      ),
    );
  }
}
