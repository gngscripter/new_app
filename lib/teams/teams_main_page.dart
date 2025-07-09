import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_teams_page.dart';
import 'create_team_page.dart';

class TeamsMainPage extends StatefulWidget {
  final String username;
  final bool isSupervisor;

  const TeamsMainPage({
    super.key,
    required this.username,
    required this.isSupervisor,
  });

  @override
  State<TeamsMainPage> createState() => _TeamsMainPageState();
}

class _TeamsMainPageState extends State<TeamsMainPage> {
  String? _selectedEmployeeId;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          if (widget.isSupervisor)
            IconButton(
              icon: const Icon(Icons.person_search),
              onPressed: _showEmployeeSelectionDialog,
              tooltip: 'Select Employee',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_selectedEmployeeId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_selectedEmployeeId)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Text('Loading...');
                        final userData = snapshot.data!.data() as Map<String, dynamic>?;
                        return Text('Viewing: ${userData?['name'] ?? 'Unknown'}');
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedEmployeeId = null),
                    ),
                  ),
                ),
              ),
            ElevatedButton.icon(
              icon: const Icon(Icons.group),
              label: const Text('My Teams'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyTeamsPage(
                      userId: _auth.currentUser!.uid,
                      isSupervisor: widget.isSupervisor,
                      selectedEmployeeId: _selectedEmployeeId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedEmployeeId == null) // Only show Create Team when not viewing employee's teams
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTeamPage(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEmployeeSelectionDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Employee'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('position', isEqualTo: 'employee')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final employees = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final employee = employees[index].data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(employee['name'] as String),
                    subtitle: Text(employee['email'] as String),
                    onTap: () {
                      setState(() => _selectedEmployeeId = employees[index].id);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}