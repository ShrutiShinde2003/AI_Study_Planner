import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class FirebaseGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _groupsCollection => _firestore.collection('groups');

  /// Send Message (Includes Sender's Username)
  Future<void> sendMessage(String groupId, String messageText) async {
    if (messageText.trim().isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) throw Exception("User data not found");

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
      String senderName = userData['userName'] ?? 'Unknown'; // Store sender's username

      DocumentReference messageRef =
          _groupsCollection.doc(groupId).collection('messages').doc();

      Message newMessage = Message(
        id: messageRef.id,
        senderId: user.uid,
        senderName: senderName, // Stores sender's username
        text: messageText.trim(),
        timestamp: Timestamp.now(),
      );

      await messageRef.set(newMessage.toMap());
    } catch (e) {
      print("❌ Error sending message: $e");
    }
  }

  ///  Fetch Messages
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

        return true; // Member added
      }
      return false; // ❌ User not found
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
        return []; // ❌ Group or members field not found
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
}
