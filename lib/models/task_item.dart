import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  String uid;
  String subject;
  String task;
  String description;
  String dueDate;
  String status;
  DateTime timeCreated;

  TaskModel({
    required this.uid,
    required this.subject,
    required this.task,
    required this.description,
    required this.dueDate,
    this.status = "pending",
    required this.timeCreated,
  });

  // Convert TaskModel instance to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "subject": subject,
      "task": task,
      "description": description,
      "due_date": dueDate,
      "status": status,
      "time_created": timeCreated,
    };
  }

  // Create a TaskModel from a Firestore document snapshot
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      uid: map["uid"] ?? "",
      subject: map["subject"] ?? "",
      task: map["task"] ?? "",
      description: map["description"] ?? "",
      dueDate: map["due_date"] ?? "",
      status: map["status"] ?? "pending",
      timeCreated: (map["time_created"] as Timestamp).toDate(),
    );
  }
}
