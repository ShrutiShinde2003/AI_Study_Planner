import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final String? fileUrl;
  final String? fileName;
  final String type;
  final Timestamp timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    this.fileUrl,
    this.fileName,
    required this.type,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
      type: data['type'] ?? 'text',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'type': type,
      'timestamp': timestamp,
    };
  }
}
