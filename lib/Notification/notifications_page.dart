import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'TaskDetailsPage.dart';

class NotificationsPage extends StatelessWidget {
  final String username;
  final String? filterKeyword;
  final String? title;

  const NotificationsPage({
    super.key,
    required this.username,
    this.filterKeyword,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUsername = username.trim().toLowerCase();

    final query = FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: normalizedUsername);

    final filteredStream = (filterKeyword != null && filterKeyword!.isNotEmpty)
        ? query.where('type', isEqualTo: filterKeyword!.toLowerCase()).snapshots()
        : query.snapshots();

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: filteredStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading notifications."));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No notifications found."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final message = data['message'] ?? '';
              final taskId = data['taskId'];
              final timestamp = data['timestamp'];
              final read = data['read'] ?? false;

              final date = timestamp is Timestamp ? timestamp.toDate() : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    Icons.notifications,
                    color: read ? Colors.grey : Colors.yellow,
                  ),
                  title: Text(
                    message,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: date != null
                      ? Text(
                      '${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}')
                      : const Text('No timestamp'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final docId = docs[index].id;

                    // Mark as read
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(docId)
                        .update({'read': true});

                    // Navigate to task detail if taskId is present
                    if (taskId != null && taskId.toString().isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailsPage(taskId: taskId),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                            Text("This notification isn't linked to any task.")),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
