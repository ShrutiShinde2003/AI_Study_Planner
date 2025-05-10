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
  List<String> userSubjects = []; // Stores the user's subjects

  @override
  void initState() {
    super.initState();
    fetchUserSubjects(); // Fetch subjects when Dashboard loads
  }

  // 🔹 Fetch user's subjects from Firestore
  Future<void> fetchUserSubjects() async {
    final user = _auth.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      setState(() {
        userSubjects = List<String>.from(
            (userDoc.data() as Map<String, dynamic>)['subjects'] ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Dashboard'),
        automaticallyImplyLeading: false,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('uid', isEqualTo: _auth.currentUser?.uid)
            .where('isCompleted', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Firestore Error: ${snapshot.error}");
            return Center(child: Text("Error loading data"));
          }

          Map<String, int> completedTasks = {};
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            String subject = (data.containsKey('subject') &&
                    data['subject'] != null &&
                    data['subject'].toString().isNotEmpty)
                ? data['subject']
                : 'No Subject';
            if (userSubjects.contains(subject)) {
              completedTasks[subject] = (completedTasks[subject] ?? 0) + 1;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Task Completion by Subject",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                if (completedTasks.isEmpty)
                  Center(
                    child: Text(
                      'No completed assignments yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                else
                  Column(
                    children: [
                      SizedBox(
                        height: 220,
                        child: PieChart(
                          PieChartData(
                            sections: _getChartSections(completedTasks),
                            centerSpaceRadius: 40,
                            sectionsSpace: 3,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: completedTasks.length,
                        separatorBuilder: (_, __) => SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          String subject = completedTasks.keys.elementAt(index);
                          int taskCount = completedTasks[subject]!;

                          return Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[850]
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .shadowColor
                                      .withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              leading: CircleAvatar(
                                backgroundColor: _getColorForSubject(subject),
                                child: Icon(Icons.check, color: Colors.white),
                              ),
                              title: Text(
                                subject,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                "$taskCount Tasks Completed",
                                style: TextStyle(color: Colors.green[700]),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

// Pie chart section generator
  List<PieChartSectionData> _getChartSections(Map<String, int> completedTasks) {
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

// Color palette by subject
  Color _getColorForSubject(String subject) {
    const colors = [
      Colors.blue,
      Colors.red,
      Color(0xFF41DD46),
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Color(0xFFB3164A),
      Colors.cyan,
      Colors.indigo,
      Colors.lime,
      Colors.brown,
    ];
    return colors[subject.hashCode % colors.length];
  }
}
