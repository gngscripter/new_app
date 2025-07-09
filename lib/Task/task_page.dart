import 'package:flutter/material.dart';
import 'assigned_page.dart';
import 'completed_page.dart';
import 'todo_page.dart';

class TaskPage extends StatelessWidget {
  final String currentUser;

  const TaskPage({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRoundedButton(
              label: 'Assigned',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AssignedTasks(currentUser: currentUser),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRoundedButton(
              label: 'Completed',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CompletedTasks(currentUser: currentUser),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRoundedButton(
              label: 'To Do',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ToDoTasks(currentUser: currentUser),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundedButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(40),
        ),
        textStyle: const TextStyle(fontSize: 20),
      ),
      child: Text(label),
    );
  }
}
