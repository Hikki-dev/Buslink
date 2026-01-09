import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../utils/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                size: 20,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text("Please login to view notifications")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text("No notifications yet",
                      style:
                          TextStyle(color: Colors.grey.withValues(alpha: 0.8))),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index].data() as Map<String, dynamic>;
              final bool isRead = notif['isRead'] ?? false;
              final Timestamp? ts = notif['timestamp'];

              return Container(
                color: isRead
                    ? Colors.transparent
                    : AppTheme.primaryColor.withValues(alpha: 0.05),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    notif['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(notif['body'] ?? ''),
                      const SizedBox(height: 6),
                      if (ts != null)
                        Text(
                          DateFormat('MMM d, h:mm a').format(ts.toDate()),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Icon(_getIconForType(notif['type']),
                        color: AppTheme.primaryColor, size: 20),
                  ),
                  onTap: () async {
                    // Mark as read
                    if (!isRead) {
                      await FirebaseFirestore.instance
                          .collection('notifications')
                          .doc(notifications[index].id)
                          .update({'isRead': true});
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'trip_update':
        return Icons.directions_bus;
      case 'refund_update':
        return Icons.monetization_on;
      case 'cancellation':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }
}
