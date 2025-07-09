import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Detail_Page.dart';

class AssignedTasks extends StatelessWidget {
  final String currentUser;

  const AssignedTasks({super.key, required this.currentUser});

  Future<void> _handleAccept(String docId, String fromUser) async {
    final normalizedFrom = fromUser.trim().toLowerCase();
    final normalizedCurrent = currentUser.trim().toLowerCase();

    await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
      'status': 'due',
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'to': normalizedFrom,
      'message': "$normalizedCurrent accepted your task",
      'timestamp': FieldValue.serverTimestamp(),
      'taskId': docId,
      'type': 'accepted',
      'read': false, // ✅ Mark unread
    });
  }

  Future<void> _handleDecline(String docId, String fromUser) async {
    final normalizedFrom = fromUser.trim().toLowerCase();
    final normalizedCurrent = currentUser.trim().toLowerCase();

    await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
      'status': 'declined',
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'to': normalizedFrom,
      'message': "$normalizedCurrent declined your task",
      'timestamp': FieldValue.serverTimestamp(),
      'taskId': docId,
      'type': 'declined',
      'read': false, // ✅ Mark unread
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Tasks')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('to', isEqualTo: currentUser.trim().toLowerCase())
            .where('status', whereIn: ['assigned', 'due', 'declined'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks.'));
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final doc = tasks[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;

              final from = data['from'];
              final type = data['type'];
              final status = data['status'];
              final fromRole = data['fromRole'] ?? 'employee';

              Color borderColor = Colors.grey;
              if (status == 'declined' || type == 'overdue') {
                borderColor = Colors.red;
              } else {
                borderColor = Colors.yellow;
              }

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ListTile(
                  title: Text('Task ${index + 1}'),
                  subtitle: Text('From: $from ($fromRole) | Type: $type'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailsPage(taskId: docId),
                    ),
                  ),
                  trailing: status == 'assigned'
                      ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle,
                            color: Colors.green),
                        tooltip: 'Accept',
                        onPressed: () => _handleAccept(docId, from),
                      ),
                      IconButton(
                        icon:
                        const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Decline',
                        onPressed: () => _handleDecline(docId, from),
                      ),
                    ],
                  )
                      : Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Chip(
                      label: Text(
                        status == 'due' ? 'Due' : 'Declined',
                        style: TextStyle(
                          color: status == 'due'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.grey.shade100,
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
