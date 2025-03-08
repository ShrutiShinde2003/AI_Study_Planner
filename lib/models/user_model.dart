import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;
  List<String> subjects;
  List<String> followers;
  List<String> following;
  String profileImage; // ✅ Added field for profile image

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.subjects,
    required this.followers,
    required this.following,
    required this.profileImage, // ✅ Initialize profile image
  });

  // ✅ Convert the UserModel object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'subjects': subjects,
      'followers': followers,
      'following': following,
      'profileImage': profileImage, // ✅ Store profile image path
    };
  }

  // ✅ Create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      email: data['email'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      profileImage: data['profileImage'] ?? '', // ✅ Load profile image path
    );
  }
}
