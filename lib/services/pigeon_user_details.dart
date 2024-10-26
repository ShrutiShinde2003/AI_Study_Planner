import 'package:firebase_auth/firebase_auth.dart';

class PigeonUserDetails {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;

  PigeonUserDetails({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
  });

  // Factory constructor to create a PigeonUserDetails instance from Firebase User
  factory PigeonUserDetails.fromFirebaseUser(User user) {
    return PigeonUserDetails(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  // To handle a list of users
  static List<PigeonUserDetails> fromFirebaseUserList(List<User> users) {
    return users
        .map((user) => PigeonUserDetails.fromFirebaseUser(user))
        .toList();
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
