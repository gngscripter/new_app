import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BinPage extends StatelessWidget {
  final String deletedBy;

  const BinPage({super.key, required this.deletedBy});

  Future<void> _clearBin(BuildContext context) async {
    final lowerDeletedBy = deletedBy.trim().toLowerCase();

    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('deletedBy', isEqualTo: lowerDeletedBy)
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bin cleared successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lowerDeletedBy = deletedBy.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deleted Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Clear Bin',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Bin?'),
                  content: const Text(
                      'Are you sure you want to permanently delete all tasks from the bin?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _clearBin(context);
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('deletedBy', isEqualTo: lowerDeletedBy)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No deleted tasks.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              try {
                final data = docs[index].data() as Map<String, dynamic>;

                final toUser = data['to'] ?? 'Unknown';
                final message = data['message'] ?? '';
                final type = data['type'] ?? '';
                final deadlineTimestamp = data['deadline'];

                String formattedDeadline = 'No deadline';
                if (deadlineTimestamp is Timestamp) {
                  final deadline = deadlineTimestamp.toDate();
                  formattedDeadline =
                      DateFormat('dd MMM yyyy • hh:mm a').format(deadline);
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      toUser,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(message),
                        const SizedBox(height: 4),
                        Text("Type: $type"),
                        Text("Deadline: $formattedDeadline"),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                return ListTile(
                  title: const Text("Error displaying task"),
                  subtitle: Text(e.toString()),
                );
              }
            },
          );
        },
      ),
    );
  }
}
