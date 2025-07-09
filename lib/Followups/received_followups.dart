import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReceivedFollowUpPage extends StatelessWidget {
  final String currentUser;

  const ReceivedFollowUpPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final normalizedUser = currentUser.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Received Follow-ups"),
        backgroundColor: const Color(0xFFF2F2F2),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('followups')
            .where('to', isEqualTo: normalizedUser)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 🔴 Error Handling
          if (snapshot.hasError) {
            debugPrint("Firestore Error: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          // ⏳ Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 📭 Empty Data Handling
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No follow-ups received."));
          }

          // ✅ Data Available
          final followups = snapshot.data!.docs;

          return ListView.builder(
            itemCount: followups.length,
            itemBuilder: (context, index) {
              final data = followups[index].data() as Map<String, dynamic>;

              final from = data['from'] ?? 'Unknown';
              final taskMessage = data['taskMessage'] ?? 'No task';
              final message = data['message'] ?? 'No message';
              final timestamp = data['timestamp'] as Timestamp?;

              final timeStr = timestamp != null
                  ? DateFormat('dd MMM yyyy • hh:mm a').format(timestamp.toDate())
                  : 'Unknown time';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("From: $from", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Task: $taskMessage", style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Text("“$message”", style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 6),
                      Text(timeStr, style: const TextStyle(color: Colors.grey)),
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
