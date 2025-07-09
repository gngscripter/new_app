import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailsPage extends StatelessWidget {
  final String taskId;

  const DetailsPage({super.key, required this.taskId});

  Future<void> _markComplete(BuildContext context, String fromUser, String toUser) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': 'completed',
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'to': fromUser.trim().toLowerCase(),
      'message': "$toUser marked the task as completed.",
      'timestamp': FieldValue.serverTimestamp(),
      'taskId': taskId,
      'type': 'completed',
      'read': false, // ✅ Unread when created
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

          if (data == null) return const Center(child: Text("Task not found."));

          final message = data['message'] ?? '';
          final fromUser = data['from'] ?? '';
          final toUser = data['to'] ?? '';
          final status = data['status'] ?? '';
          final deadlineTimestamp = data['deadline'];
          String formattedDeadline = 'Not set';

          if (deadlineTimestamp != null && deadlineTimestamp is Timestamp) {
            final deadline = deadlineTimestamp.toDate();
            formattedDeadline = '${deadline.day}/${deadline.month}/${deadline.year} at ${deadline.hour}:${deadline.minute.toString().padLeft(2, '0')}';
          }

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: ListView(
                    children: [
                      const Text("Task:",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(message, style: const TextStyle(fontSize: 16)),

                      const SizedBox(height: 24),
                      Text("From: $fromUser"),
                      Text("To: $toUser"),
                      Text("Status: $status"),
                      Text("Deadline: $formattedDeadline"),
                    ],
                  ),
                ),
              ),

              if (status != 'completed')
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ElevatedButton(
                    onPressed: () => _markComplete(context, fromUser, toUser),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Mark as Complete"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
