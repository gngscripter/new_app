// ✅ EmployeeDashboard.dart (Updated to use 'fromRole')

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class EmployeeDashboard extends StatefulWidget {
  final String username;

  const EmployeeDashboard({super.key, required this.username});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  Map<String, int> stats = {
    'total': 0,
    'sentByEmployee': 0,
    'sentBySupervisor': 0,
    'waitingOverdue': 0,
    'waitingNormal': 0,
    'acceptedOverdue': 0,
    'acceptedNormal': 0,
    'rejectedOverdue': 0,
    'rejectedNormal': 0,
    'completedOverdue': 0,
    'completedNormal': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final allTasks = await FirebaseFirestore.instance.collection('tasks').get();
    final myTasks = allTasks.docs.where((doc) => doc['to'] == widget.username).toList();

    int sentByEmployee = 0;
    int sentBySupervisor = 0;
    int waitingOverdue = 0, waitingNormal = 0;
    int acceptedOverdue = 0, acceptedNormal = 0;
    int rejectedOverdue = 0, rejectedNormal = 0;
    int completedOverdue = 0, completedNormal = 0;

    for (var doc in myTasks) {
      final data = doc.data() as Map<String, dynamic>;
      final fromRole = data['fromRole'];
      final type = data['type'];
      final status = data['status'];

      if (fromRole == 'supervisor') {
        sentBySupervisor++;
      } else {
        sentByEmployee++;
      }

      if (status == 'assigned') {
        if (type == 'overdue') waitingOverdue++;
        else waitingNormal++;
      } else if (status == 'due') {
        if (type == 'overdue') acceptedOverdue++;
        else acceptedNormal++;
      } else if (status == 'declined') {
        if (type == 'overdue') rejectedOverdue++;
        else rejectedNormal++;
      } else if (status == 'completed') {
        if (type == 'overdue') completedOverdue++;
        else completedNormal++;
      }
    }

    setState(() {
      stats = {
        'total': myTasks.length,
        'sentByEmployee': sentByEmployee,
        'sentBySupervisor': sentBySupervisor,
        'waitingOverdue': waitingOverdue,
        'waitingNormal': waitingNormal,
        'acceptedOverdue': acceptedOverdue,
        'acceptedNormal': acceptedNormal,
        'rejectedOverdue': rejectedOverdue,
        'rejectedNormal': rejectedNormal,
        'completedOverdue': completedOverdue,
        'completedNormal': completedNormal,
      };
    });
  }

  Widget buildStatRow(String title, int overdue, int normal) {
    final total = overdue + normal;

    List<PieChartSectionData> sections;
    if (total == 0) {
      sections = [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          title: 'No data',
          titleStyle: const TextStyle(fontSize: 10, color: Colors.black),
        ),
      ];
    } else {
      sections = [
        PieChartSectionData(
          value: overdue.toDouble(),
          color: Colors.red,
          title: '${((overdue / total) * 100).toStringAsFixed(1)}%',
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
        PieChartSectionData(
          value: normal.toDouble(),
          color: Colors.green,
          title: '${((normal / total) * 100).toStringAsFixed(1)}%',
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Overdue: $overdue', style: const TextStyle(color: Colors.red)),
                Text('Normal: $normal', style: const TextStyle(color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 120,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 20,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Tasks Assigned to You: ${stats['total']}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tasks Sent by Employees: ${stats['sentByEmployee']}'),
            Text('Tasks Sent by Supervisors: ${stats['sentBySupervisor']}'),
            const Divider(height: 32, thickness: 1),

            buildStatRow('Waiting Tasks', stats['waitingOverdue']!, stats['waitingNormal']!),
            buildStatRow('Accepted Tasks', stats['acceptedOverdue']!, stats['acceptedNormal']!),
            buildStatRow('Rejected Tasks', stats['rejectedOverdue']!, stats['rejectedNormal']!),
            buildStatRow('Completed Tasks', stats['completedOverdue']!, stats['completedNormal']!),
          ],
        ),
      ),
    );
  }
}
