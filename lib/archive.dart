import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ArchivePage extends StatefulWidget {
  final String senderUsername;

  const ArchivePage({super.key, required this.senderUsername});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  List<DocumentSnapshot> visibleDocs = [];

  @override
  Widget build(BuildContext context) {
    final lowerSender = widget.senderUsername.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Sent Tasks'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('from', isEqualTo: lowerSender)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data?.docs ?? [];

          // ✅ Filter deleted tasks locally (instead of Firestore query)
          visibleDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['deletedBy'] == null;
          }).toList();

          if (visibleDocs.isEmpty) {
            return const Center(child: Text("No sent tasks found."));
          }

          return ListView.builder(
            itemCount: visibleDocs.length,
            itemBuilder: (context, index) {
              final doc = visibleDocs[index];
              final data = doc.data() as Map<String, dynamic>;

              final toUser = data['to'] ?? 'Unknown';
              final message = data['message'] ?? '';
              final type = data['type'] ?? '';
              final deadlineTimestamp = data['deadline'];

              String formattedDeadline = 'No deadline';
              if (deadlineTimestamp is Timestamp) {
                final deadline = deadlineTimestamp.toDate();
                formattedDeadline = DateFormat('dd MMM yyyy • hh:mm a').format(deadline);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    toUser == lowerSender ? "$toUser (myself)" : toUser,
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(doc.id)
                            .update({'deletedBy': lowerSender});

                        setState(() {
                          visibleDocs.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sent to bin')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
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
