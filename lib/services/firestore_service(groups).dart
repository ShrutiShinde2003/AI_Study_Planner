// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../models/group_model.dart';
// import '../models/message_model.dart';

// class FirebaseGroupService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   /// ✅ Create a New Group
//   Future<void> createGroup(String groupName, List<String> members) async {
//     try {
//       final user = _auth.currentUser;
//       if (user == null) throw Exception("User not logged in");

//       DocumentReference groupRef = _firestore.collection('groups').doc();

//       Group newGroup = Group(
//         id: groupRef.id,
//         name: groupName,
//         createdBy: user.uid,
//         members: {...members, user.uid}.toList(), // Ensuring uniqueness
//         createdAt: Timestamp.now(),
//       );

//       await groupRef.set(newGroup.toMap());
//       print("✅ Group created successfully!");
//     } catch (e) {
//       print("❌ Error creating group: $e");
//     }
//   }

//   /// ✅ Send a Message in a Group
//   Future<void> sendMessage(String groupId, String messageText) async {
//     if (messageText.trim().isEmpty) return;

//     final user = _auth.currentUser;
//     if (user == null) return;

//     try {
//       // 🔍 Fetch user's details (username + email)
//       DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
//       if (!userDoc.exists) throw Exception("User data not found");
      
//       Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>? ?? {};
//       String userName = userData['userName'] ?? 'Unknown';
//       String senderEmail = userData['email'] ?? 'No Email';

//       DocumentReference messageRef =
//           _firestore.collection('groups').doc(groupId).collection('messages').doc();

//       Message newMessage = Message(
//         id: messageRef.id,
//         groupId: groupId,
//         senderId: user.uid,
//         userName: userName,
//         senderEmail: senderEmail,
//         text: messageText.trim(),
//         timestamp: Timestamp.now(),
//       );

//       await messageRef.set(newMessage.toMap());
//       print("✅ Message Sent: ${newMessage.toMap()}");
//     } catch (e) {
//       print("❌ Error sending message: $e");
//     }
//   }

//   /// ✅ Fetch All Messages in a Group
//   Stream<List<Message>> getGroupMessages(String groupId) {
//     return _firestore
//         .collection('groups')
//         .doc(groupId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false)
//         .snapshots()
//         .map((snapshot) {
//           if (snapshot.docs.isEmpty) {
//             print("⚠️ No messages found!");
//             return [];
//           }
//           return snapshot.docs.map((doc) {
//             try {
//               return Message.fromMap(doc.data() as Map<String, dynamic>, doc.id);
//             } catch (e) {
//               print("❌ Error parsing message: $e");
//               return null;
//             }
//           }).whereType<Message>().toList();
//         });
//   }
// }
