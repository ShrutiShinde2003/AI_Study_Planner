import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;
  List<String> subjects;
  List<String> followers; // Add followers list
  List<String> following; // Add following list

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.subjects,
    required this.followers, // Initialize followers
    required this.following, // Initialize following
  });

  // Convert the UserModel object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'subjects': subjects,
      'followers': followers, // Store followers
      'following': following, // Store following
    };
  }

  // Create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      email: data['email'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      followers: List<String>.from(data['followers'] ?? []), // Handle followers
      following: List<String>.from(data['following'] ?? []), // Handle following
    );
  }
}
