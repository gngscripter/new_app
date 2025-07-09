import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'archive.dart';

class RequestPage extends StatefulWidget {
  final String senderUsername;

  const RequestPage({super.key, required this.senderUsername});

  @override
  State<RequestPage> createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  String selectedUser = '';
  String taskType = 'normal';
  final TextEditingController _taskController = TextEditingController();
  DateTime? selectedDate;
  List<String> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final senderName = widget.senderUsername.trim().toLowerCase();

    setState(() {
      users = snapshot.docs
          .map((doc) => doc['name'].toString().trim().toLowerCase())
          .toSet()
          .toList();

      if (!users.contains(senderName)) users.add(senderName);
      selectedUser = users.first;
    });
  }

  Future<void> _sendTask() async {
    if (_taskController.text.trim().isEmpty || selectedUser.isEmpty) return;

    String senderRole = 'employee';
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isEqualTo: widget.senderUsername.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      if (data.containsKey('role')) {
        senderRole = data['role'].toString().trim().toLowerCase();
      }
    }

    final isSelfAssigned =
        selectedUser == widget.senderUsername.trim().toLowerCase();
    final taskStatus = isSelfAssigned ? 'todo' : 'assigned';

    final taskRef = await FirebaseFirestore.instance.collection('tasks').add({
      'from': widget.senderUsername.trim().toLowerCase(),
      'fromRole': senderRole,
      'to': selectedUser.trim().toLowerCase(),
      'message': _taskController.text.trim(),
      'type': taskType,
      'status': taskStatus,
      'deadline': selectedDate,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!isSelfAssigned) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'to': selectedUser.trim().toLowerCase(),
        'from': widget.senderUsername.trim().toLowerCase(),
        'message': 'You received a new task.',
        'type': 'general',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'taskId': taskRef.id,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSelfAssigned
              ? "Task added to your To Do list!"
              : "Task sent successfully!",
        ),
      ),
    );

    _taskController.clear();
    setState(() => selectedDate = null);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 7)),
    );

    if (pickedDate != null) {
      final pickedTime =
      await showTimePicker(context: context, initialTime: TimeOfDay.now());

      if (pickedTime != null) {
        setState(() {
          selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = selectedDate != null
        ? DateFormat('dd MMM yyyy • hh:mm a').format(selectedDate!)
        : 'Select Deadline';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            tooltip: 'View Archive',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ArchivePage(senderUsername: widget.senderUsername),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send To', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedUser,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: users
                    .map(
                      (user) => DropdownMenuItem(
                    value: user,
                    child: Text(
                      user ==
                          widget.senderUsername
                              .trim()
                              .toLowerCase()
                          ? "$user (myself)"
                          : user,
                    ),
                  ),
                )
                    .toList(),
                onChanged: (value) =>
                    setState(() => selectedUser = value!),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _taskController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type your request here',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => taskType = 'Urgent'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: taskType == 'Urgent'
                            ? Colors.red
                            : Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Urgent'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => taskType = 'normal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: taskType == 'normal'
                            ? Colors.green
                            : Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Normal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _pickDate(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedDate == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _sendTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 48, vertical: 16),
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
