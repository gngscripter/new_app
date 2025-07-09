import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskDetailsPage extends StatelessWidget {
  final String taskId;

  const TaskDetailsPage({super.key, required this.taskId});

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'due':
        return Colors.amber;
      case 'followup':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  Future<void> markCompleted(BuildContext context) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': 'completed',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task marked as completed!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tasks').doc(taskId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) return const Center(child: Text("Task not found"));

          final status = data['status'] ?? 'unknown';
          final deadline = data['deadline'];
          final fromRole = data['fromRole'] ?? 'employee';

          String? formattedDeadline;
          if (deadline is Timestamp) {
            formattedDeadline = DateFormat('dd MMM yyyy').format(deadline.toDate());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    Text("Task Message",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(data['message'] ?? '', style: const TextStyle(fontSize: 16)),

                    const SizedBox(height: 20),
                    Text("From: ${data['from']}"),
                    Text("Sender Role: $fromRole"),
                    Text("To: ${data['to']}"),
                    Text("Type: ${data['type']}"),
                    if (formattedDeadline != null)
                      Text("Deadline: $formattedDeadline"),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("Status: ",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: getStatusColor(status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Optionally show follow-up note if exists
                    if (data.containsKey('followUpNote'))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const Text("Follow-up Note",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(data['followUpNote']),
                        ],
                      ),

                    const SizedBox(height: 24),

                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
