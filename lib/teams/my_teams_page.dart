import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'TeamMembersPage.dart';

class MyTeamsPage extends StatelessWidget {
  final String userId;
  final bool isSupervisor;
  final String? selectedEmployeeId;

  const MyTeamsPage({
    super.key,
    required this.userId,
    this.isSupervisor = false,
    this.selectedEmployeeId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedEmployeeId != null ? 'Employee Teams' : 'My Teams'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('teams')
            .where('members', arrayContains: selectedEmployeeId ?? userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final teams = snapshot.data?.docs ?? [];

          if (teams.isEmpty) {
            return const Center(
              child: Text('No teams found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index].data() as Map<String, dynamic>;
              final teamId = teams[index].id;
              final isAdmin = (team['admins'] as List).contains(userId);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(team['name'] as String),
                  subtitle: team['description'] != null
                      ? Text(team['description'] as String)
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdmin && !isSupervisor)
                        IconButton(
                          icon: const Icon(Icons.group),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TeamMembersPage(
                                  teamId: teamId,
                                  teamName: team['name'],
                                  members: List<String>.from(team['members']),
                                  admins: List<String>.from(team['admins']),
                                ),
                              ),
                            );
                          },
                          tooltip: 'View Members',
                        ),
                      const Icon(Icons.chat),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          teamId: teamId,
                          teamName: team['name'] as String,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
