// lib/models/todo_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;

  UserModel({required this.uid, required this.userName, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'userId': uid,
      'email': email,
      'name': userName,
    };
  }

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'],
      userName: data['userName'] ?? '',
      email: data['email'],
    );
  }

  // // Create a To-Do item from a Firestore document
  // factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
  //   return UserModel(
  //     uid: documentId,
  //     userName: map['userName'] ?? '',
  //     email: map['email'],
  //   );
  // }
}