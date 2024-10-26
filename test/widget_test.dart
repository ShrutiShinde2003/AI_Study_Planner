// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
// import 'package:provider/provider.dart';
// import 'package:study_planner/main.dart';
// import 'package:study_planner/pages/home_page.dart';
// import 'package:study_planner/pages/todo_list_page.dart';
// import 'package:study_planner/models/todo_item.dart';
// import 'package:study_planner/services/firestore_service.dart';
// import 'package:study_planner/services/pigeon_user_details.dart'; // Added this import

// // Create a proper mock class for FirestoreService
// class MockFirestoreService extends Mock implements FirestoreService {}

// // Create a proper mock class for PigeonUserDetails
// class MockPigeonUserDetails extends Mock implements PigeonUserDetails {
//   @override
//   String? get displayName => 'Test User';
  
//   @override
//   String get email => 'test@example.com';
// }

// class PigeonUserDetails {
// }

// void main() {
//   group('App Tests', () {
//     late MockFirestoreService mockFirestoreService;

//     setUp(() {
//       mockFirestoreService = MockFirestoreService();
//     });

//     testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//       await tester.pumpWidget(const MyApp());

//       expect(find.text('0'), findsOneWidget);
//       expect(find.text('1'), findsNothing);

//       await tester.tap(find.byIcon(Icons.add));
//       await tester.pump();

//       expect(find.text('0'), findsNothing);
//       expect(find.text('1'), findsOneWidget);
//     });

//     testWidgets('App initializes with Home Page', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: HomePage(userDetails: MockPigeonUserDetails()),
//         ),
//       );

//       expect(find.text('Home Page'), findsOneWidget);
//     });

//     testWidgets('Navigates to To-Do List Page on button tap', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: HomePage(userDetails: MockPigeonUserDetails()),
//         ),
//       );

//       final todoButton = find.text('Go to To-Do List');
//       expect(todoButton, findsOneWidget);
//       await tester.tap(todoButton);
//       await tester.pumpAndSettle();

//       expect(find.text('To-Do List'), findsOneWidget);
//     });

//     testWidgets('Adds a To-Do item', (WidgetTester tester) async {
//       when(mockFirestoreService.getTodoList())
//           .thenAnswer((_) => Stream.value([]));

//       await tester.pumpWidget(
//         ChangeNotifierProvider<FirestoreService>.value(
//           value: mockFirestoreService,
//           child: MaterialApp(
//             home: TodoListPage(),
//           ),
//         ),
//       );

//       final todoField = find.byType(TextField);
//       final addButton = find.text('Add');

//       await tester.enterText(todoField, 'Test To-Do');
//       await tester.tap(addButton);
//       await tester.pump();

//       verify(mockFirestoreService.addTodoItem(any)).called(1);
//     });

//     testWidgets('Deletes a To-Do item', (WidgetTester tester) async {
//       final testTodo = TodoItem(
//         id: '1', 
//         title: 'Test To-Do', 
//         isCompleted: false,
//       );

//       when(mockFirestoreService.getTodoList())
//           .thenAnswer((_) => Stream.value([testTodo]));

//       await tester.pumpWidget(
//         ChangeNotifierProvider<FirestoreService>.value(
//           value: mockFirestoreService,
//           child: MaterialApp(
//             home: TodoListPage(),
//           ),
//         ),
//       );

//       final deleteIcon = find.byIcon(Icons.delete);
//       expect(deleteIcon, findsOneWidget);
//       await tester.tap(deleteIcon);
//       await tester.pump();

//       verify(mockFirestoreService.deleteTodoItem(testTodo.id)).called(1);
//     });
//   });
// }