import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;
  List<String> subjects; // Add subjects list

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.subjects, // Initialize subjects
  });

  // Convert the UserModel object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'subjects': subjects, // Store subjects
    };
  }

  // Create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      email: data['email'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []), // Handle subjects
    );
  }
}
