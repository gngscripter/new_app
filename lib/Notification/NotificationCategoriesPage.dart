import 'package:flutter/material.dart';
import 'Notifications_page.dart';

class NotificationCategoriesPage extends StatelessWidget {
  final String username;

  const NotificationCategoriesPage({super.key, required this.username});

  void _navigateToFilteredNotifications(BuildContext context, String keyword, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(
          username: username,
          filterKeyword: keyword,
          title: title,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      String keyword,
      ) {
    return InkWell(
      onTap: () => _navigateToFilteredNotifications(context, keyword, title),
      borderRadius: BorderRadius.circular(12),
      splashColor: color.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 22,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Categories')),
      body: ListView(
        padding: const EdgeInsets.only(top: 20, bottom: 20),
        children: [
          _buildCategoryTile(context, 'Accepted Tasks', Icons.check_circle, Colors.blue, 'accepted'),
          _buildCategoryTile(context, 'Rejected Tasks', Icons.cancel, Colors.red, 'declined'),
          _buildCategoryTile(context, 'Completed Tasks', Icons.done_all, Colors.green, 'completed'),
          _buildCategoryTile(context, 'Follow Ups', Icons.loop, Colors.orange, 'follow up'),
        ],
      ),
    );
  }
}

