import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class FirebaseGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _groupsCollection => _firestore.collection('groups');

  /// Send Text Message + Push Notification
  Future<void> sendMessage(String groupId, String messageText) async {
    if (messageText.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) throw Exception("User data not found");

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
      String senderName = userData['userName'] ?? 'Unknown';

      DocumentReference messageRef = _groupsCollection.doc(groupId).collection('messages').doc();

      Message newMessage = Message(
        id: messageRef.id,
        senderId: user.uid,
        senderName: senderName,
        text: messageText.trim(),
        fileUrl: null,
        fileName: null,
        type: 'text',
        timestamp: Timestamp.now(),
      );

      await messageRef.set(newMessage.toMap());

      // Send push notifications to group members (excluding sender)
      DocumentSnapshot groupDoc = await _groupsCollection.doc(groupId).get();
      List members = (groupDoc['members'] as List?) ?? [];

      for (String memberId in members) {
        if (memberId == user.uid) continue;

        DocumentSnapshot memberDoc = await _usersCollection.doc(memberId).get();
        final memberData = memberDoc.data() as Map<String, dynamic>?;

        final token = memberData?['fcmToken'];
        if (token != null) {
          await sendPushNotification(token, senderName, messageText);
        }
      }
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  Future<void> sendPushNotification(String token, String senderName, String messageText) async {
    const serverKey = 'YOUR_SERVER_KEY'; // 🔑 Replace with your actual Firebase server key

    final data = {
      "to": token,
      "notification": {
        "title": "$senderName in group chat",
        "body": messageText,
        "sound": "default"
      },
      "priority": "high"
    };

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "key=$serverKey"
    };

    final response = await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      print("❌ Failed to send push notification: ${response.body}");
    }
  }

  /// Send Note Message (PDF Upload)
  Future<void> sendNoteMessage(String groupId, String fileName, String fileUrl) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    final fixedUrl = fileUrl.replaceFirst('/image/upload/', '/raw/upload/');

    DocumentSnapshot userDoc = await _usersCollection.doc(currentUser.uid).get();
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
    String senderName = userData['userName'] ?? 'Unknown';

    final messageRef = _groupsCollection.doc(groupId).collection('messages').doc();

    final message = Message(
      id: messageRef.id,
      senderId: currentUser.uid,
      senderName: senderName,
      text: '',
      fileName: fileName,
      fileUrl: fixedUrl,
      type: 'note',
      timestamp: Timestamp.now(),
    );

    await messageRef.set(message.toMap());
  }

  /// Fetch Messages Stream
  Stream<List<Message>> getGroupMessages(String groupId) {
    return _groupsCollection
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Message.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Add Member to Group by Username
  Future<bool> addMemberByUsername(String groupId, String username) async {
    try {
      QuerySnapshot userSnapshot = await _usersCollection
          .where('userName', isEqualTo: username)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        String userIdToAdd = userSnapshot.docs.first.id;

        await _groupsCollection.doc(groupId).update({
          'members': FieldValue.arrayUnion([userIdToAdd])
        });

        return true;
      }
      return false;
    } catch (e) {
      print("❌ Error adding member: $e");
      return false;
    }
  }

  /// Fetch Group Members
  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    try {
      DocumentSnapshot groupSnapshot = await _groupsCollection.doc(groupId).get();
      if (!groupSnapshot.exists || !groupSnapshot.data().toString().contains('members')) {
        return [];
      }

      List members = (groupSnapshot['members'] as List?) ?? [];
      if (members.isEmpty) return [];

      List<DocumentSnapshot> userSnapshots = await Future.wait(
        members.map((memberId) => _usersCollection.doc(memberId).get()),
      );

      return userSnapshots
          .where((userDoc) => userDoc.exists)
          .map((userDoc) => userDoc.data() as Map<String, dynamic>? ?? {})
          .toList();
    } catch (e) {
      print("❌ Error fetching members: $e");
      return [];
    }
  }

  /// Leave Group
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _groupsCollection.doc(groupId).update({
        'members': FieldValue.arrayRemove([user.uid])
      });
    }
  }
}