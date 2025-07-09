import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Notification/NotificationTabsPage.dart';
import 'Task/task_page.dart';
import 'request.dart';
import 'Dashboard/employee_dashboard.dart';
import 'Dashboard/supervisor_dashboard.dart';
import 'Followups/FollowUpMainPage.dart';
import 'teams/teams_main_page.dart';
import 'bin_page.dart';

class Homepage extends StatelessWidget {
  final String username;
  final String position;

  const Homepage({
    super.key,
    required this.username,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Stack(
          children: [
            // ────────── MAIN CONTENT ──────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi $username',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(position, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),

                      // Notification bell with live unread‑count badge
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('notifications')
                            .where('to', isEqualTo: username.trim().toLowerCase())
                            .where('read', isEqualTo: false)
                            .snapshots(),
                        builder: (context, snapshot) {
                          final int unread = snapshot.hasData ? snapshot.data!.docs.length : 0;

                          return Stack(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications, size: 28),
                                tooltip: 'Notifications',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => NotificationTabsPage(username: username),
                                    ),
                                  );
                                },
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$unread',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Navigation buttons ──
                  buildNavButton(context, 'Tasks', TaskPage(currentUser: username)),
                  const SizedBox(height: 20),

                  buildNavButton(context, 'Requests', RequestPage(senderUsername: username)),
                  const SizedBox(height: 20),

                  buildNavButton(context, 'Follow up', FollowUpMainPage(currentUser: username)),
                  const SizedBox(height: 20),

                  buildNavButton(
                    context,
                    'Dashboard',
                    position.toLowerCase() == 'supervisor'
                        ? SupervisorDashboard(supervisorName: username)
                        : EmployeeDashboard(username: username),
                  ),
                  const SizedBox(height: 20),

                  buildNavButton(
                    context,
                    'Teams',
                    TeamsMainPage(
                      username: username,
                      isSupervisor: position.toLowerCase() == 'supervisor',
                    ),
                  ),

                  const Spacer(),

                  // ── Footer ──
                  Center(
                    child: Text(
                      'MTA  ∑MTC',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // ────────── Floating Bin Button (Accent Blue) ──────────
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BinPage(deletedBy: username)),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent, width: 3),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.delete, color: Colors.blueAccent, size: 28),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to build a full‑width navigation button
  Widget buildNavButton(BuildContext context, String label, Widget page) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
