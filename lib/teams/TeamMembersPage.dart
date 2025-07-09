import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamMembersPage extends StatefulWidget {
  final String teamName;
  final List<String> members;
  final List<String> admins;
  final String teamId;

  const TeamMembersPage({
    super.key,
    required this.teamName,
    required this.members,
    required this.admins,
    required this.teamId,
  });

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  List<Map<String, dynamic>>? userList;
  List<String> memberIds = [];
  List<String> adminIds = [];
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    memberIds = List<String>.from(widget.members);
    adminIds = List<String>.from(widget.admins);
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    if (memberIds.isEmpty) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .get();

    setState(() {
      userList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  bool get isCurrentUserAdmin => adminIds.contains(currentUserId);
  bool get isOnlyAdmin => adminIds.length == 1 && adminIds.contains(currentUserId);

  Future<void> _makeAdmin(String uid) async {
    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .update({
      'admins': FieldValue.arrayUnion([uid]),
    });

    setState(() => adminIds.add(uid));
  }

  Future<void> _removeAdmin(String uid) async {
    if (adminIds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one admin is required.")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .update({
      'admins': FieldValue.arrayRemove([uid]),
    });

    setState(() => adminIds.remove(uid));
  }

  Future<void> _removeMember(String uid) async {
    if (uid == currentUserId && adminIds.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are the only admin. Promote someone else before leaving.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).update({
      'members': FieldValue.arrayRemove([uid]),
      'admins': FieldValue.arrayRemove([uid]), // also remove from admin if present
    });

    setState(() {
      memberIds.remove(uid);
      adminIds.remove(uid);
      userList?.removeWhere((user) => user['uid'] == uid);
    });

    if (memberIds.isEmpty) {
      // dissolve team
      await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _addMembers() async {
    final allUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();

    final nonMembers = allUsersSnapshot.docs.where((doc) => !memberIds.contains(doc.id)).toList();
    final Set<String> selected = {};

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Members'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: StatefulBuilder(
            builder: (context, setState) => ListView.builder(
              itemCount: nonMembers.length,
              itemBuilder: (_, index) {
                final user = nonMembers[index].data() as Map<String, dynamic>;
                final uid = nonMembers[index].id;
                return CheckboxListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                  value: selected.contains(uid),
                  onChanged: (val) {
                    setState(() {
                      val! ? selected.add(uid) : selected.remove(uid);
                    });
                  },
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            child: const Text('Add'),
            onPressed: () async {
              if (selected.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('teams')
                    .doc(widget.teamId)
                    .update({'members': FieldValue.arrayUnion(selected.toList())});

                setState(() => memberIds.addAll(selected));
                await _loadUserDetails();
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteTeam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete this team? This cannot be undone."),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('teams').doc(widget.teamId).delete();
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Team deleted successfully")),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to delete team: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userList == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.teamName} Members')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: userList!.length,
              itemBuilder: (context, index) {
                final user = userList![index];
                final uid = user['uid'];
                final isAdmin = adminIds.contains(uid);
                final isMe = uid == currentUserId;

                return ListTile(
                  leading: Icon(isAdmin ? Icons.shield : Icons.person,
                      color: isAdmin ? Colors.orange : null),
                  title: Text(user['name'] ?? 'No Name'),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: isCurrentUserAdmin && !isMe
                      ? PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'make_admin') _makeAdmin(uid);
                      if (value == 'remove_admin') _removeAdmin(uid);
                      if (value == 'remove_member') _removeMember(uid);
                    },
                    itemBuilder: (context) => [
                      if (!isAdmin)
                        const PopupMenuItem(value: 'make_admin', child: Text('Make Admin')),
                      if (isAdmin)
                        const PopupMenuItem(value: 'remove_admin', child: Text('Remove Admin')),
                      const PopupMenuItem(value: 'remove_member', child: Text('Remove Member')),
                    ],
                  )
                      : null,
                );
              },
            ),
          ),
          if (isOnlyAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever),
                label: const Text("Delete Team"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: _confirmDeleteTeam,
              ),
            ),
        ],
      ),
      floatingActionButton: isCurrentUserAdmin
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text("Add"),
        onPressed: _addMembers,
      )
          : null,
    );
  }
}
