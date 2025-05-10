import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String uid;
  final String userText;
  final String geminiText;
  final Timestamp timestamp;
  final int sequenceNo;
  final String subjectText;

  ChatMessage({
    required this.uid,
    required this.userText,
    required this.geminiText,
    required this.timestamp,
    required this.sequenceNo,
    required this.subjectText,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userText': userText,
      'geminiText': geminiText,
      'timestamp': timestamp,
      'sequenceNo': sequenceNo,
      'subjectText': subjectText,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      uid: map['uid'],
      userText: map['userText'] ?? '',
      geminiText: map['geminiText'] ?? '',
      timestamp: map['timestamp'],
      sequenceNo: map['sequenceNo'] ?? 0,
      subjectText: map['subjectText'] ?? '',
    );
  }
}