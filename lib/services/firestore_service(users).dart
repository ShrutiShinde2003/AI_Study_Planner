import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Follow a user
  Future<void> followUser(String currentUserId, String targetUserId) async {
    var userRef = _firestore.collection('users');

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot currentUserSnapshot =
            await transaction.get(userRef.doc(currentUserId));
        DocumentSnapshot targetUserSnapshot =
            await transaction.get(userRef.doc(targetUserId));

        if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception("User not found");
        }

        // Add target user to "following" list of current user
        transaction.update(userRef.doc(currentUserId), {
          "following": FieldValue.arrayUnion([targetUserId])
        });

        // Add current user to "followers" list of target user
        transaction.update(userRef.doc(targetUserId), {
          "followers": FieldValue.arrayUnion([currentUserId])
        });
      });

      print("✅ Followed user successfully!");
    } catch (error) {
      print("❌ Error following user: $error");
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String currentUserId, String targetUserId) async {
    var userRef = _firestore.collection('users');

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot currentUserSnapshot =
            await transaction.get(userRef.doc(currentUserId));
        DocumentSnapshot targetUserSnapshot =
            await transaction.get(userRef.doc(targetUserId));

        if (!currentUserSnapshot.exists || !targetUserSnapshot.exists) {
          throw Exception("User not found");
        }

        // Remove target user from "following" list
        transaction.update(userRef.doc(currentUserId), {
          "following": FieldValue.arrayRemove([targetUserId])
        });

        // Remove current user from "followers" list of target user
        transaction.update(userRef.doc(targetUserId), {
          "followers": FieldValue.arrayRemove([currentUserId])
        });
      });

      print("✅ Unfollowed user successfully!");
    } catch (error) {
      print("❌ Error unfollowing user: $error");
    }
  }

  // Remove a follower
  Future<void> removeFollower(String currentUserId, String followerId) async {
    var userRef = _firestore.collection('users');

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot currentUserSnapshot =
            await transaction.get(userRef.doc(currentUserId));
        DocumentSnapshot followerSnapshot =
            await transaction.get(userRef.doc(followerId));

        if (!currentUserSnapshot.exists || !followerSnapshot.exists) {
          throw Exception("User not found");
        }

        // Remove follower from "followers" list
        transaction.update(userRef.doc(currentUserId), {
          "followers": FieldValue.arrayRemove([followerId])
        });

        // Remove yourself from their "following" list
        transaction.update(userRef.doc(followerId), {
          "following": FieldValue.arrayRemove([currentUserId])
        });
      });

      print("✅ Successfully removed follower: $followerId");
    } catch (error) {
      print("❌ Error removing follower: $error");
    }
  }
}
