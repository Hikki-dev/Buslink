import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_theme.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
// 
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
        title: Text("Notifications",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                  Text("No notifications",
                      style:
                          TextStyle(color: Colors.grey.withValues(alpha: 0.8))),
                ],
              ),
            );
          }

          // FILTER: Only show Important Notifications (Delayed, Cancelled, Refunded)
          final notifications = snapshot.data!.where((n) {
            return n.type == NotificationType.cancellation ||
                n.type == NotificationType.delay ||
                n.type == NotificationType.refundStatus;
          }).toList();

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 60, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text("No important alerts",
                      style:
                          TextStyle(color: Colors.grey.withValues(alpha: 0.8))),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox.shrink(),
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
    // Determine Color and Icon based on Type + Title (Accessibility Enrichment)
    IconData icon = Icons.notifications;
    Color color = AppTheme.primaryColor;
    String statusText = "INFO";

    switch (notif.type) {
      case NotificationType.tripStatus:
        if (notif.title.contains("Departed") ||
            notif.title.contains("On Way")) {
          icon = Icons.directions_bus;
          color = Colors.blue;
          statusText = "ON WAY";
        } else if (notif.title.contains("Arrived")) {
          icon = Icons.check_circle;
          color = Colors.green;
          statusText = "ARRIVED";
        } else {
          icon = Icons.schedule;
          color = Colors.orange;
          statusText = "SCHEDULED";
        }
        break;
      case NotificationType.refundStatus:
        if (notif.title.toLowerCase().contains("approved") ||
            notif.body.toLowerCase().contains("refunded")) {
          icon = Icons.monetization_on;
          color = Colors.green;
          statusText = "REFUNDED";
        } else if (notif.title.toLowerCase().contains("rejected")) {
          icon = Icons.error_outline;
          color = Colors.red;
          statusText = "REJECTED";
        } else {
          icon = Icons.refresh;
          color = Colors.orange;
          statusText = "PROCESSING";
        }
        break;
      case NotificationType.cancellation:
        icon = Icons.cancel;
        color = Colors.red;
        statusText = "CANCELLED";
        break;
      case NotificationType.delay:
        icon = Icons.timer_off;
        color = Colors.redAccent;
        statusText = "DELAYED";
        break;
      case NotificationType.general:
        icon = Icons.notifications;
        color = AppTheme.primaryColor;
        statusText = "NEW";
        break;
      case NotificationType.booking:
        icon = Icons.confirmation_number;
        color = Colors.green;
        statusText = "CONFIRMED";
        break;
    }

    // Override info if read
    if (notif.isRead) {
      // color = Colors.grey; // Optional: Grey out read notifications?
      // Keeping original color but maybe dimming opacity could work,
      // but users prefer keeping color context.
    }

    return GestureDetector(
      onTap: () async {
        if (!notif.isRead) {
          await NotificationService.markAsRead(notif.id);
        }
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored Strip
              Container(
                  width: 6,
                  color: notif.isRead ? color.withValues(alpha: 0.5) : color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(notif.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 16,
                                          fontWeight: notif.isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                    DateFormat('h:mm a')
                                        .format(notif.timestamp),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade400)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(notif.body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.7) ??
                                        Colors.grey)),
                            const SizedBox(height: 8),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text(statusText,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
