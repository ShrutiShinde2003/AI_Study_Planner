import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:study_planner/models/todo_item.dart';
import 'package:study_planner/services/firestore_service.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, int> _completedAssignments = {};

  @override
  void initState() {
    super.initState();
    _fetchCompletedAssignments();
  }

  void _fetchCompletedAssignments() async {
    final todoList = await _firestoreService.getTodoListOnce();
    final Map<String, int> subjectCount = {};

    for (var todo in todoList) {
      if (todo.isCompleted) {
        subjectCount[todo.title] = (subjectCount[todo.title] ?? 0) + 1;
      }
    }

    setState(() {
      _completedAssignments = subjectCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assignments Donut Chart'),
      ),
      body: _completedAssignments.isEmpty
          ? Center(child: Text('No completed assignments yet'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: PieChart(
                PieChartData(
                  sections: _getChartSections(),
                  centerSpaceRadius: 60,
                  sectionsSpace: 2,
                ),
              ),
            ),
    );
  }

  List<PieChartSectionData> _getChartSections() {
    return _completedAssignments.entries.map((entry) {
      final percentage = (entry.value / _completedAssignments.values.reduce((a, b) => a + b)) * 100;
      return PieChartSectionData(
        color: _getColorForSubject(entry.key),
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getColorForSubject(String subject) {
    // Assign colors for each subject dynamically
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    return colors[subject.hashCode % colors.length];
  }
}
