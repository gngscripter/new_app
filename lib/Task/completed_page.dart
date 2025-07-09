import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Detail_Page.dart';

class CompletedTasks extends StatefulWidget {
  final String currentUser;
  const CompletedTasks({super.key, required this.currentUser});

  @override
  State<CompletedTasks> createState() => _CompletedTasksState();
}

class _CompletedTasksState extends State<CompletedTasks> {
  List<DocumentSnapshot> visibleDocs = [];

  @override
  Widget build(BuildContext context) {
    final currentUserLower = widget.currentUser.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(title: const Text("Completed Tasks")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('to', isEqualTo: currentUserLower)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allTasks = snapshot.data!.docs;

          // Filter out tasks already deleted
          visibleDocs = allTasks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['deletedBy'] == null;
          }).toList();

          if (visibleDocs.isEmpty) return const Center(child: Text("Nothing finished yet."));

          return ListView.builder(
            itemCount: visibleDocs.length,
            itemBuilder: (context, index) {
              final doc = visibleDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final docId = doc.id;
              final from = data['from'];
              final type = data['type'];
              final fromRole = data['fromRole'] ?? 'employee';

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ListTile(
                  title: Text("Task ${index + 1}"),
                  subtitle: Text("From: $from ($fromRole) | Type: $type"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailsPage(taskId: docId)),
                    );
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Chip(
                        label: Text(
                          'Finished',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Color(0xFFF0FFF0),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Move to Bin',
                        onPressed: () async {
                          await FirebaseFirestore.instance.collection('tasks').doc(docId).update({
                            'deletedBy': currentUserLower,
                            'deletedFrom': 'completed', // 👈 Added field for bin tracking
                          });

                          // Immediately remove from UI
                          setState(() {
                            visibleDocs.removeAt(index);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Task sent to bin")),
                          );
                        },
                      ),
                    ],
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
