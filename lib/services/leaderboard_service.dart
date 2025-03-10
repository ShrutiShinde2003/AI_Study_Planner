import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔥 Fetch top users by XP (Leaderboard)
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    QuerySnapshot query = await _db.collection('users')
      .orderBy('xp', descending: true)
      .limit(10)
      .get();

    return query.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
