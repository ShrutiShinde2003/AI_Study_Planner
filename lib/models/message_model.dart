import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String fileUrl; // ✅ Added file URL for PDFs & images
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.fileUrl = "", // ✅ Default empty string for non-file messages
    required this.timestamp,
  });

  /// 🔹 Convert Firestore document to `Message` object
  factory Message.fromMap(Map<String, dynamic> data, String documentId) {
    return Message(
      id: documentId,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      text: data['text'] as String? ?? '',
      fileUrl: data['fileUrl'] as String? ?? '', // ✅ Load file URL safely
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// 🔹 Convert Firestore Document to `Message` Model
  factory Message.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Message(
      id: documentId,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      text: data['text'] ?? '',
      fileUrl: data['fileUrl'] ?? '', // ✅ Load file URL safely
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  /// 🔹 Convert `Message` object to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'fileUrl': fileUrl, // ✅ Save file URL
      'timestamp': timestamp,
    };
  }
}
