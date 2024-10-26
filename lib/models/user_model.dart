// lib/models/todo_item.dart

class UserModel {
  String uid;
  String userName;
  String email;

  UserModel({required this.uid, required this.userName, required this.email});

  // Convert To-Do item to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
    };
  }

  // Create a To-Do item from a Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      userName: map['userName'] ?? '',
      email: map['email'],
    );
  }
}
