import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GamificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _users => _db.collection('users');

  /// Update XP, Streaks, Task Progress, Level, and Rewards
  Future<void> updateUserProgress() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _users.doc(user.uid);

    try {
      DocumentSnapshot userDoc = await userRef.get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        int xp = userData['xp'] ?? 0;
        int streak = userData['streak'] ?? 0;
        int taskProgress = userData['taskProgress'] ?? 0;
        int level = userData['level'] ?? 1;
        int rewards = userData['rewards'] ?? 0;
        List<String> badges = List<String>.from(userData['badges'] ?? []);

        // 🔥 XP Increases by 10 per Task
        xp += 10;
        taskProgress += 1;

        // 🔥 Streak Logic (Check if last task was yesterday)
        DateTime lastTaskDate = (userData['lastTaskDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (DateTime.now().difference(lastTaskDate).inDays == 1) {
          streak += 1; // Maintain streak
        } else if (DateTime.now().difference(lastTaskDate).inDays > 1) {
          streak = 1; // Streak Reset
        }

        // 🎁 Every 5 Tasks → Reward & Level Up!
        if (taskProgress >= 5) {
          rewards += 1;
          taskProgress = 0;
          level += 1;
          String? newBadge = _getBadge(level, xp);
          if (newBadge != null && !badges.contains(newBadge)) {
            badges.add(newBadge);
          }
        }

        // Update Firestore
        await userRef.update({
          'xp': xp,
          'streak': streak,
          'taskProgress': taskProgress,
          'level': level,
          'rewards': rewards,
          'badges': badges,
          'lastTaskDate': Timestamp.now(),
        });

        print("✅ User XP, streak, and progress updated!");
      }
    } catch (e) {
      print("❌ Error updating progress: $e");
    }
  }

  /// 🔥 **Fix: Handle XP & Streak Reset When Tasks Are Deleted**
  Future<void> resetUserProgressIfTasksDeleted() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _users.doc(user.uid);
    
    try {
      QuerySnapshot taskSnapshot = await _db
          .collection('tasks')
          .where('uid', isEqualTo: user.uid)
          .get();

      if (taskSnapshot.docs.isEmpty) {
        print("⚠️ No tasks found. Resetting progress...");

        await userRef.update({
          'completedTasksCount': 0,
          'xp': 0, // 🔥 Reset XP to 0
          'taskProgress': 0,
          'level': 1, // 🔥 Reset level to 1
          'rewards': 0,
          'streak': 0,  // 🔥 Reset streak
          'badges': [],  // 🔥 Remove badges
        });

        print("✅ User progress reset due to task deletion.");
      }
    } catch (e) {
      print("❌ Error resetting user progress: $e");
    }
  }

  /// **Fix XP Deduction When Tasks Are Deleted**
  Future<void> deductXPOnTaskDelete() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _users.doc(user.uid);

    try {
      DocumentSnapshot userDoc = await userRef.get();
      if (!userDoc.exists) return;

      int xp = userDoc['xp'] ?? 0;
      if (xp > 0) xp -= 10; // 🔥 Deduct XP only if it's greater than 0

      await userRef.update({'xp': xp});
      print("✅ XP deducted on task deletion: New XP = $xp");
    } catch (e) {
      print("❌ Error deducting XP: $e");
    }
  }

  /// 🏅 Assign Badges for Levels & XP
  String? _getBadge(int level, int xp) {
    if (level == 5) return "Beginner Mastery";
    if (level == 10) return "Intermediate Achiever";
    if (level == 20) return "Advanced Warrior";
    if (xp >= 500) return "XP Champion";
    return null;
  }
}
