import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'TaskDetailsPage.dart';

class NotificationTabsPage extends StatelessWidget {
  final String username;

  const NotificationTabsPage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5, // Increased from 4 to 5
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              _buildTabWithBadge('Accepted', username, 'accepted'),
              _buildTabWithBadge('Declined', username, 'declined'),
              _buildTabWithBadge('Completed', username, 'completed'),
              _buildTabWithBadge('Follow-ups', username, 'followup'),
              _buildTabWithBadge('General', username, 'general'), // ✅ New Tab
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NotificationList(type: 'accepted', username: username),
            NotificationList(type: 'declined', username: username),
            NotificationList(type: 'completed', username: username),
            NotificationList(type: 'followup', username: username),
            NotificationList(type: 'general', username: username), // ✅ New Tab Body
          ],
        ),
      ),
    );
  }

  Widget _buildTabWithBadge(String label, String username, String type) {
    final normalizedUsername = username.trim().toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('to', isEqualTo: normalizedUsername)
          .where('type', isEqualTo: type)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}

class NotificationList extends StatelessWidget {
  final String type;
  final String username;

  const NotificationList({super.key, required this.type, required this.username});

  @override
  Widget build(BuildContext context) {
    final normalizedUsername = username.trim().toLowerCase();

    final stream = FirebaseFirestore.instance
        .collection('notifications')
        .where('to', isEqualTo: normalizedUsername)
        .where('type', isEqualTo: type)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
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
                  color: read ? Colors.grey : Colors.orange,
                ),
                title: Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: date != null
                    ? Text(DateFormat('dd MMM yyyy • hh:mm a').format(date))
                    : const Text('No timestamp'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final docId = snapshot.data!.docs[index].id;

                  // Mark as read
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(docId)
                      .update({'read': true});

                  // Open TaskDetailsPage if taskId is available
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
    );
  }
}
