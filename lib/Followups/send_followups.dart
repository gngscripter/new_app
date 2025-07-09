import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SendFollowUpPage extends StatefulWidget {
  final String currentUser;

  const SendFollowUpPage({super.key, required this.currentUser});

  @override
  State<SendFollowUpPage> createState() => _SendFollowUpPageState();
}

class _SendFollowUpPageState extends State<SendFollowUpPage> {
  String? selectedUser;
  String? selectedTaskId;
  Map<String, dynamic>? selectedTaskData;

  final TextEditingController _messageController = TextEditingController();

  List<String> userList = [];
  List<Map<String, dynamic>> taskList = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('to', isEqualTo: widget.currentUser.trim().toLowerCase())
          .where('status', isEqualTo: 'due') // ✅ Only due tasks
          .get();

      final users = snapshot.docs
          .map((doc) => doc['from'].toString().trim().toLowerCase())
          .toSet()
          .toList();

      setState(() {
        userList = users;
      });
    } catch (e) {
      debugPrint("Error loading users: $e");
    }
  }

  Future<void> _loadTasksForUser(String user) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('to', isEqualTo: widget.currentUser.trim().toLowerCase())
          .where('from', isEqualTo: user.trim().toLowerCase())
          .where('status', isEqualTo: 'due') // ✅ Only due tasks
          .get();

      final tasks = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'message': doc['message'] ?? 'No message',
          'from': doc['from'],
          'deadline': doc['deadline'],
        };
      }).toList();

      setState(() {
        taskList = tasks;
        selectedTaskId = null;
        selectedTaskData = null;
      });
    } catch (e) {
      debugPrint("Error loading tasks: $e");
    }
  }

  Future<void> _sendFollowUp() async {
    final message = _messageController.text.trim();
    if (selectedUser == null || selectedTaskId == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select user, task and enter a message")),
      );
      return;
    }

    try {
      // Confirm task still valid
      final taskSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(selectedTaskId)
          .get();

      if (!taskSnapshot.exists || taskSnapshot['status'] == 'completed') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot send follow-up on a completed task.")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('followups').add({
        'from': widget.currentUser.trim().toLowerCase(),
        'to': selectedUser!.trim().toLowerCase(),
        'taskId': selectedTaskId,
        'taskMessage': selectedTaskData!['message'],
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'to': selectedUser!.trim().toLowerCase(),
        'type': 'followup',
        'taskId': selectedTaskId,
        'message': "You have a new follow-up from ${widget.currentUser}",
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      _messageController.clear();
      setState(() {
        selectedTaskId = null;
        selectedTaskData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Follow-up sent successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  String formatDeadline(dynamic deadline) {
    if (deadline == null) return 'None';
    try {
      final ts = deadline as Timestamp;
      final date = ts.toDate();
      return DateFormat('dd MMM yyyy • hh:mm a').format(date);
    } catch (_) {
      return 'Invalid';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Follow-up"),
        backgroundColor: const Color(0xFFF2F2F2),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select User',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              value: selectedUser,
              items: userList
                  .map((user) => DropdownMenuItem<String>(
                value: user,
                child: Text(user),
              ))
                  .toList(),
              onChanged: (user) {
                if (user == null) return;
                setState(() {
                  selectedUser = user;
                });
                _loadTasksForUser(user);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Task',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
              value: selectedTaskId,
              items: List.generate(taskList.length, (index) {
                final task = taskList[index];
                return DropdownMenuItem<String>(
                  value: task['id'],
                  child: Text('Task ${index + 1}'),
                );
              }),
              onChanged: (id) {
                final task = taskList.firstWhere((t) => t['id'] == id);
                setState(() {
                  selectedTaskId = id;
                  selectedTaskData = task;
                });
              },
            ),
            if (selectedTaskData != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Task ${taskList.indexWhere((t) => t['id'] == selectedTaskId) + 1}: ${selectedTaskData!['message']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text("By: ${selectedTaskData!['from']}"),
                    Text("Deadline: ${formatDeadline(selectedTaskData!['deadline'])}"),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Message",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sendFollowUp,
              icon: const Icon(Icons.send),
              label: const Text("Send Follow-up"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
