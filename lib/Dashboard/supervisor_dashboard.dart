import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SupervisorDashboard extends StatefulWidget {
  final String supervisorName;

  const SupervisorDashboard({super.key, required this.supervisorName});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  String selectedEmployee = '';
  List<String> employeeList = [];
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
    _loadEmployees();
    _fetchStats(widget.supervisorName); // Show own dashboard by default
  }

  Future<void> _loadEmployees() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final names = snapshot.docs
        .where((doc) => doc['role'].toLowerCase() != 'supervisor')
        .map((doc) => doc['name'].toString().trim().toLowerCase())
        .toList();

    setState(() {
      employeeList = names;
    });
  }

  Future<void> _fetchStats(String username) async {
    final allTasks = await FirebaseFirestore.instance.collection('tasks').get();
    final myTasks = allTasks.docs.where((doc) => doc['to'] == username).toList();

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
    final currentTarget = selectedEmployee.isEmpty ? widget.supervisorName : selectedEmployee;

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard: $currentTarget')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employeeList.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Employee:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedEmployee.isEmpty ? widget.supervisorName : selectedEmployee,
                    items: [
                      DropdownMenuItem(
                        value: widget.supervisorName,
                        child: Text('${widget.supervisorName} (You)'),
                      ),
                      ...employeeList.map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                      ),
                    ],
                    onChanged: (value) {
                      final actualValue = value == widget.supervisorName ? '' : value!;
                      setState(() {
                        selectedEmployee = actualValue;
                      });
                      _fetchStats(value!);
                    },
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Text('Total Tasks Assigned to $currentTarget: ${stats['total']}', style: const TextStyle(fontSize: 16)),
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
