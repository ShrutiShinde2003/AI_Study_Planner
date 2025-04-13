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
  List<String> userSubjects = []; //  Stores the user's subjects

  @override
  void initState() {
    super.initState();
    fetchUserSubjects(); //  Fetch subjects when Dashboard loads
  }

  // 🔹 Fetch user's subjects from Firestore
  Future<void> fetchUserSubjects() async {
    final user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        userSubjects = List<String>.from((userDoc.data() as Map<String, dynamic>)['subjects'] ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        automaticallyImplyLeading: false, // 🚀 Removes the back button
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('uid', isEqualTo: _auth.currentUser?.uid)
            .where('isCompleted', isEqualTo: true) //  Fetch only completed tasks
            .snapshots(), //  Real-time updates
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator()); // 🔹 Show loading
          }

          if (snapshot.hasError) {
            print(" Firestore Error: ${snapshot.error}");
            return Center(child: Text("Error loading data"));
          }

          // 🔹 Process completed tasks by subject
          Map<String, int> completedTasks = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;

            //  Ensure the subject is correctly fetched from Firestore
            String subject = (data.containsKey('subject') && data['subject'] != null && data['subject'].toString().isNotEmpty)
                ? data['subject']
                : 'No Subject'; // 🔹 Prevents "Unknown"

            //  Only show tasks from subjects that still exist in the profile
            if (userSubjects.contains(subject)) {
              completedTasks[subject] = (completedTasks[subject] ?? 0) + 1;
            }
          }

          return SingleChildScrollView(
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
                  completedTasks.isEmpty
                      ? Center(child: Text('No completed assignments yet'))
                      : Column(
                          children: [
                            SizedBox(
                              height: 200, //  Fixed height for Pie Chart
                              child: PieChart(
                                PieChartData(
                                  sections: _getChartSections(completedTasks),
                                  centerSpaceRadius: 50,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // 🔹 List of Subjects with Task Count
                            ListView.builder(
                              shrinkWrap: true, //  Prevents layout issues
                              physics: NeverScrollableScrollPhysics(), // Fixes nested scrolling
                              itemCount: completedTasks.length,
                              itemBuilder: (context, index) {
                                String subject = completedTasks.keys.elementAt(index);
                                int taskCount = completedTasks[subject]!;

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
                                      "$taskCount Tasks Completed",
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
          );
        },
      ),
    );
  }

  // 🔹 Generate Pie Chart Sections Dynamically
  List<PieChartSectionData> _getChartSections(Map<String, int> completedTasks) {
    if (completedTasks.isEmpty) return [];

    int totalCompleted = completedTasks.values.fold(0, (sum, val) => sum + val);

    return completedTasks.entries.map((entry) {
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

  // 🔹 Assign Unique Colors to Subjects
  Color _getColorForSubject(String subject) {
    const colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.pink, Colors.yellow, Colors.cyan, Colors.indigo,
      Colors.lime, Colors.brown,
    ];
    return colors[subject.hashCode % colors.length]; // Generates consistent color
  }
}