import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'TeamMembersPage.dart';

class ChatPage extends StatefulWidget {
  final String teamId;
  final String teamName;

  const ChatPage({super.key, required this.teamId, required this.teamName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<String> members = [];
  List<String> admins = [];

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  void _loadTeamData() async {
    final teamDoc = await FirebaseFirestore.instance
        .collection('teams')
        .doc(widget.teamId)
        .get();

    if (teamDoc.exists) {
      final data = teamDoc.data();
      if (mounted) {
        setState(() {
          members = List<String>.from(data?['members'] ?? []);
          admins = List<String>.from(data?['admins'] ?? []);
        });
      }
    }
  }

  void sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _messageController.text.trim().isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .collection('chats')
          .add({
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'message': _messageController.text.trim(),
        'timestamp': Timestamp.now(), // Keep using Firestore Timestamp
      });

      _messageController.clear();
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  void _openTeamMembersPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamMembersPage(
          teamName: widget.teamName,
          teamId: widget.teamId,
          members: members,
          admins: admins,
        ),
      ),
    ).then((_) {
      _loadTeamData(); // Reload in case of changes
    });
  }

  String timeAgoInSeconds(DateTime time) {
    final secondsAgo = DateTime.now().difference(time).inSeconds;
    if (secondsAgo < 1) return "just now";
    return "$secondsAgo s ago";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamName),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _openTeamMembersPage,
            tooltip: 'View Team Members',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('teams')
                  .doc(widget.teamId)
                  .collection('chats')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                // Sort manually just in case Firestore didn't
                messages.sort((a, b) {
                  final timeA = (a['timestamp'] as Timestamp).toDate();
                  final timeB = (b['timestamp'] as Timestamp).toDate();
                  return timeA.compareTo(timeB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final doc = messages[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final isMe = data['senderId'] ==
                        FirebaseAuth.instance.currentUser?.uid;
                    final senderName = data['senderName'];
                    final message = data['message'];
                    final timestamp = (data['timestamp'] as Timestamp).toDate();

                    final bool showName = index == 0 ||
                        (messages[index - 1].data()
                        as Map<String, dynamic>)['senderId'] !=
                            data['senderId'];

                    return Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (showName)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 2),
                            child: Text(
                              senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 2),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                            isMe ? Colors.blue[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message),
                              const SizedBox(height: 4),
                              Text(
                                timeAgoInSeconds(timestamp),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 3),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Send Message',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}