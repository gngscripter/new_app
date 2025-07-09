import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Detail_Page.dart';

/// ---------------------------------------------------------------------------
///  TO‑DO TASKS PAGE – shows ONLY tasks you assigned to **yourself**
///  ---------------------------------------------------------------------------
///  • A task counts as “To Do” when both `assignedBy` **and** `assignedTo` match
///    the current user (self‑assigned) and is not yet completed.
///  • Colour logic is unchanged (urgent = orange, normal = yellow, overdue = red).
///  • UI layout kept exactly the same as before.
/// ---------------------------------------------------------------------------
class ToDoTasks extends StatelessWidget {
  final String currentUser;

  const ToDoTasks({super.key, required this.currentUser});

  // ──────────────────────────────────────────────────────────────────────────
  // Helper: choose border colour based on type & deadline
  // ──────────────────────────────────────────────────────────────────────────
  Color _getBorderColor(String type, DateTime? deadline) {
    final now = DateTime.now();
    if (deadline != null && deadline.isBefore(now)) {
      return Colors.red; // Overdue
    }
    switch (type.toLowerCase()) {
      case 'urgent':
        return Colors.orange.shade300;          // light orange
      default:
        return Colors.yellow.shade600;          // normal -> yellow
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UI
  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final normalizedUser = currentUser.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text('To Do Tasks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('from', isEqualTo: normalizedUser)
            .where('to', isEqualTo: normalizedUser)
            .where('status', isEqualTo: 'todo')             //   still pending
        // Removed orderBy to avoid composite‑index error; uncomment if you
        // create an index: .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // ──  Error / loading handling ────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading tasks: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return const Center(child: Text('No To Do tasks'));
          }

          // ──  Task list ───────────────────────────────────────────────────
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final doc = tasks[index];
              final data = doc.data() as Map<String, dynamic>;

              final message   = data['message']  ?? '';
              final type      = (data['type']    ?? 'normal').toString();
              final deadline  = (data['deadline'] as Timestamp?)?.toDate();
              final docId     = doc.id;

              final borderColor = _getBorderColor(type, deadline);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ListTile(
                  title: Text(message),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type: ${type}'),
                      if (deadline != null)
                        Text('Deadline: ${deadline.toLocal()}'),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(taskId: docId),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
