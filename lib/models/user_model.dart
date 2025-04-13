import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String userName;
  String email;
  List<String> subjects;
  List<String> followers;
  List<String> following;
  String profileImage;
  int xp; // ✅ XP for gamification
  int taskProgress; // ✅ Tracks completed tasks before reward
  int level; // ✅ User level
  int rewards; // ✅ Rewards earned
  int streak; // 🔥 NEW: Daily streak tracking
  DateTime lastTaskDate; // 📅 NEW: Last task completed date
  List<String> badges; // 🏅 List of earned badges

  UserModel({
    required this.uid,
    required this.userName,
    required this.email,
    required this.subjects,
    required this.followers,
    required this.following,
    required this.profileImage,
    this.xp = 0,
    this.taskProgress = 0,
    this.level = 1,
    this.rewards = 0,
    this.streak = 0, // 🔥 Default streak is 0
    DateTime? lastTaskDate, // 📅 Default to null
    this.badges = const [],
  }) : lastTaskDate = lastTaskDate ?? DateTime.now();

  /// 🔄 Convert UserModel to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'email': email,
      'subjects': subjects,
      'followers': followers,
      'following': following,
      'profileImage': profileImage,
      'xp': xp,
      'taskProgress': taskProgress,
      'level': level,
      'rewards': rewards,
      'streak': streak, // ✅ Save streak
      'lastTaskDate': Timestamp.fromDate(lastTaskDate), // ✅ Save last task date
      'badges': badges,
    };
  }

  /// 📝 Convert Firestore Document to UserModel
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? '',
      email: data['email'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      profileImage: data['profileImage'] ?? '',
      xp: data['xp'] ?? 0,
      taskProgress: data['taskProgress'] ?? 0,
      level: data['level'] ?? 1,
      rewards: data['rewards'] ?? 0,
      streak: data['streak'] ?? 0, // 🔥 Load streak from Firestore
      lastTaskDate: (data['lastTaskDate'] as Timestamp?)?.toDate() ??
          DateTime.now(), // 📅 Load last task date
      badges: List<String>.from(data['badges'] ?? []),
    );
  }
}