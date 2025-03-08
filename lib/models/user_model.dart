import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;
  List<String> subjects; // ✅ List of subjects
  int completedTasksCount; // ✅ New field for tracking completed tasks

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.subjects,
    required this.completedTasksCount, // ✅ Initialize completed tasks count
  });

  // Convert the UserModel object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'subjects': subjects,
      'completedTasksCount': completedTasksCount, // ✅ Store completed tasks count
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
      completedTasksCount: data['completedTasksCount'] ?? 0, // ✅ Default to 0 if missing
    );
  }
}
