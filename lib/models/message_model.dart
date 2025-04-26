import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  // Convert Firestore document to Message object
  factory Message.fromMap(Map<String, dynamic> data, String documentId) {
    return Message(
      id: documentId,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '', // Fixed field name
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert Message object to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName, // Corrected field name
      'text': text,
      'timestamp': timestamp,
    };
  }
}