import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, int> _completedTasks = {}; // Stores completed tasks per subject

  @override
  void initState() {
    super.initState();
    _fetchCompletedTasks(); // Fetch completed tasks on init
  }

  void _fetchCompletedTasks() async {
    String userId = _auth.currentUser!.uid;

    QuerySnapshot taskSnapshot = await _firestore
        .collection('tasks')
        .where('uid', isEqualTo: userId)
        .where('isCompleted', isEqualTo: true) // ✅ Fetch only completed tasks
        .get();

    Map<String, int> subjectCount = {};

    for (var doc in taskSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String subject = data['subjectName'] ?? 'Unknown';

      subjectCount[subject] = (subjectCount[subject] ?? 0) + 1;
    }

    setState(() {
      _completedTasks = subjectCount;
    });

    print("✅ Loaded Completed Tasks: $_completedTasks"); // Debugging
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard'),
      automaticallyImplyLeading: false,  // 🚀 Removes the back button
      ),
      body: SingleChildScrollView(
        // ✅ Fixes layout issues
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Task Completion by Subject",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _completedTasks.isEmpty
                  ? Center(child: Text('No completed assignments yet'))
                  : Column(
                      children: [
                        SizedBox(
                          height: 200, // ✅ Fixed height for Pie Chart
                          child: PieChart(
                            PieChartData(
                              sections: _getChartSections(),
                              centerSpaceRadius: 50,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        // 🔹 List of Subjects with Task Count
                        ListView.builder(
                          shrinkWrap: true, // ✅ Prevents layout issues
                          physics:
                              NeverScrollableScrollPhysics(), // ✅ Prevents nested scrolling issue
                          itemCount: _completedTasks.length,
                          itemBuilder: (context, index) {
                            String subject =
                                _completedTasks.keys.elementAt(index);
                            int completedTasks = _completedTasks[subject]!;
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getColorForSubject(subject),
                                  child: Icon(Icons.check, color: Colors.white),
                                ),
                                title: Text(
                                  subject,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  "$completedTasks Tasks Completed",
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _getChartSections() {
    if (_completedTasks.isEmpty) return [];

    int totalCompleted =
        _completedTasks.values.fold(0, (sum, val) => sum + val);

    return _completedTasks.entries.map((entry) {
      double percentage = (entry.value / totalCompleted) * 100;
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
    // Expanded color list to reduce duplicates
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.yellow,
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.brown,
    ];
    return colors[
        subject.hashCode % colors.length]; // Generates a consistent color
  }
}
