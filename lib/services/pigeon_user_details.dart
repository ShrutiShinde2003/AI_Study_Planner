import 'package:firebase_auth/firebase_auth.dart';

class FirebaseUserDetails {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  FirebaseUserDetails({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  // Factory constructor to create a FirebaseUserDetails instance from Firebase User
  factory FirebaseUserDetails.fromFirebaseUser(User user) {
    return FirebaseUserDetails(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  // To convert into a map if needed (for sending to Firestore/Database)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}
