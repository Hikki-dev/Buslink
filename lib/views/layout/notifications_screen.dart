import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart'; // Added Import
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
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
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppTheme.primaryColor),
            tooltip: "Mark all as read",
            onPressed: () {
              NotificationService.markAllAsRead(user.uid);
            },
          )
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.getUserNotifications(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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

          final notifications = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationItem(context, notif);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, AppNotification notif) {
    return Container(
      decoration: BoxDecoration(
        color: notif.isRead
            ? Colors.transparent
            : AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          notif.title,
          style: TextStyle(
            fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notif.body),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, h:mm a').format(notif.timestamp),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Icon(_getIconForType(notif.type),
              color: AppTheme.primaryColor, size: 20),
        ),
        onTap: () async {
          if (!notif.isRead) {
            await NotificationService.markAsRead(notif.id);
          }
        },
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.tripStatus:
        return Icons.directions_bus;
      case NotificationType.refundStatus:
        return Icons.monetization_on;
      case NotificationType.cancellation:
        return Icons.cancel;
      case NotificationType.delay:
        return Icons.timer_off; // Or specific icon for delay
      default:
        return Icons.notifications;
    }
  }
}
