// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:study_planner/services/pigeon_user_details.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Login with email and password
//   Future<PigeonUserDetails?> login(String email, String password) async {
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//       User? user = userCredential.user;

//       // Convert Firebase User to PigeonUserDetails
//       if (user != null) {
//         return PigeonUserDetails.fromFirebaseUser(user);
//       }
//       return null; // Return null if user is not found
//     } on FirebaseAuthException catch (e) {
//       // Handle Firebase-specific errors
//       if (e.code == 'user-not-found') {
//         throw Exception('No user found for that email.');
//       } else if (e.code == 'wrong-password') {
//         throw Exception('Wrong password provided.');
//       } else {
//         throw Exception('Login failed: ${e.message}');
//       }
//     } catch (e) {
//       throw Exception('Login failed: $e');
//     }
//   }

//   // Register with email and password
//   Future<PigeonUserDetails?> register(String email, String password) async {
//     try {
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email.trim(),
//         password: password.trim(),
//       );
//       User? user = userCredential.user;

//       // Convert Firebase User to PigeonUserDetails
//       if (user != null) {
//         return PigeonUserDetails.fromFirebaseUser(user);
//       }
//       return null; // Return null if user is not found
//     } on FirebaseAuthException catch (e) {
//       // Handle Firebase-specific errors
//       if (e.code == 'weak-password') {
//         throw Exception('The password provided is too weak.');
//       } else if (e.code == 'email-already-in-use') {
//         throw Exception('The account already exists for that email.');
//       } else {
//         throw Exception('Registration failed: ${e.message}');
//       }
//     } catch (e) {
//       throw Exception('Registration failed: $e');
//     }
//   }
// }
