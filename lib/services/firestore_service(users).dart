import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

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

        transaction.update(userRef.doc(currentUserId), {
          "following": FieldValue.arrayUnion([targetUserId])
        });

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

        transaction.update(userRef.doc(currentUserId), {
          "following": FieldValue.arrayRemove([targetUserId])
        });

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

        transaction.update(userRef.doc(currentUserId), {
          "followers": FieldValue.arrayRemove([followerId])
        });

        transaction.update(userRef.doc(followerId), {
          "following": FieldValue.arrayRemove([currentUserId])
        });
      });

      print("✅ Successfully removed follower: $followerId");
    } catch (error) {
      print("❌ Error removing follower: $error");
    }
  }

  //  Save Profile Image Locally with Unique Filename
  Future<void> saveImageLocally(File imageFile, String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    final localImagePath = '${directory.path}/profile_image_$userId.jpg'; // 🔥 Unique filename

    await imageFile.copy(localImagePath);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImage_$userId', localImagePath); // 🔥 Save per user

    print("✅ Saved image for $userId: $localImagePath");
  }

  // Fetch the correct profile image for each follower
  Future<String?> getFollowerProfileImage(String userId, String? firestoreImagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profileImage_$userId'); // 🔥 Fetch per user

    if (imagePath != null && File(imagePath).existsSync()) {
      print("✅ Found local image for user: $userId -> $imagePath");
      return imagePath;
    }

    if (firestoreImagePath != null && firestoreImagePath.isNotEmpty) {
      await prefs.setString('profileImage_$userId', firestoreImagePath);
      print("🔥 Saved Firestore image for $userId -> $firestoreImagePath");
      return firestoreImagePath;
    }

    print("❌ No image found for user: $userId");
    return null;
  }

  // Fetch the correct profile image for each following user
  Future<String?> getFollowingProfileImage(String userId, String? firestoreImagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profileImage_$userId'); // 🔥 Fetch per user

    if (imagePath != null && File(imagePath).existsSync()) {
      print("✅ Found local image for user: $userId -> $imagePath");
      return imagePath;
    }

    if (firestoreImagePath != null && firestoreImagePath.isNotEmpty) {
      await prefs.setString('profileImage_$userId', firestoreImagePath);
      print("🔥 Saved Firestore image for $userId -> $firestoreImagePath");
      return firestoreImagePath;
    }

    print("❌ No image found for user: $userId");
    return null;
  }
}
