// import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:workmanager/workmanager.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'main.dart'; // Import notification setup

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     DateTime now = DateTime.now();
//     QuerySnapshot tasks = await FirebaseFirestore.instance.collection('tasks')
//       .where('isCompleted', isEqualTo: false)
//       .get();

//     for (var doc in tasks.docs) {
//       var taskData = doc.data() as Map<String, dynamic>;
//       DateTime? dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();

//       if (dueDate != null && dueDate.isAfter(now) && dueDate.difference(now).inHours <= 1) {
//         await scheduleTaskNotification(doc.id, taskData['taskName'], dueDate);
//       }
//     }

//     return Future.value(true);
//   });
// }
