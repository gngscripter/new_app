import 'package:flutter/material.dart';

 class status extends StatelessWidget {
  final List<String> completedTasks = [
    "Task 1 completed on 10 June by user 1",
    "Task 2 completed on 11 June by user 3",
    "Task 3 completed on 12 June by user 2",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status'),
        backgroundColor: Colors.grey[400],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: completedTasks.map((task) {
            return Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                task,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
