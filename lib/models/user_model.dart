import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
  });

  // Convert the UserModel object to a Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Ensure this matches Firestore field names
      'userName': userName,
      'email': email,
    };
  }

  // Create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
  final data = snapshot.data();
  if (data is! Map<String, dynamic>) {
    throw Exception(
        "Invalid data type in DocumentSnapshot: Expected Map, got ${data.runtimeType}");
  }
  return UserModel(
    uid: data['uid'] ?? '',
    userName: data['userName'] ?? '',
    email: data['email'] ?? '',
  );
}
}