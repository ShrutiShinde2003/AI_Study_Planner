import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderEmail;
  final String text;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.text,
    required this.timestamp,
  });

  // Convert Firestore document to Message object
  factory Message.fromMap(Map<String, dynamic> data, String documentId) {
    return Message(
      id: documentId,
      senderId: data['senderId'] as String? ?? '',
      senderEmail: data['senderEmail'] as String? ?? '',
      text: data['text'] as String? ?? '',
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert Message object to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'text': text,
      'timestamp': timestamp,
    };
  }

  // Copy with method to create a modified copy
  Message copyWith({
    String? id,
    String? senderId,
    String? senderEmail,
    String? text,
    Timestamp? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}