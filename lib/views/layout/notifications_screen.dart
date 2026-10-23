import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/bl_colors.dart';
import '../settings/notification_settings_screen.dart';
import '../widgets/bl_widgets.dart';

/// "Notifications" (mockup "Notifications").
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          BlHeader(
            title: 'Notifications',
            actions: [
              if (user != null)
                IconButton(
                  tooltip: 'Mark all as read',
                  color: Colors.white,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  icon: const Icon(Icons.done_all),
                  onPressed: () => NotificationService.markAllAsRead(user.uid),
                ),
              IconButton(
                tooltip: 'Notification settings',
                color: Colors.white,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen())),
              ),
            ],
          ),
          Expanded(
            child: user == null
                ? const BlEmpty(
                    icon: Icons.lock_outline,
                    title: 'Please log in to continue',
                    message:
                        'Your trips and favourites are saved to your account.')
                : StreamBuilder<List<AppNotification>>(
                    stream: NotificationService.getUserNotifications(user.uid),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child:
                                CircularProgressIndicator(color: BL.crimson));
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return const BlEmpty(
                            icon: Icons.notifications_none,
                            title: 'No notifications',
                            message: 'No important alerts right now.');
                      }
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: ListView.builder(
                            itemCount: items.length,
                            itemBuilder: (_, i) => _Item(n: items[i]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} hr ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return '${d.inDays} days ago';
  return DateFormat('d MMM').format(t);
}

class _Item extends StatelessWidget {
  final AppNotification n;
  const _Item({required this.n});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (n.type) {
      case NotificationType.delay:
        icon = Icons.schedule;
        color = const Color(0xFFA64B00);
      case NotificationType.cancellation:
        icon = Icons.cancel_outlined;
        color = const Color(0xFF7F1D14);
      case NotificationType.booking:
        icon = Icons.check;
        color = BL.success;
      case NotificationType.refundStatus:
        icon = Icons.payments_outlined;
        color = const Color(0xFF374151);
      case NotificationType.tripStatus:
        icon = Icons.directions_bus;
        color = BL.crimson;
      case NotificationType.general:
        icon = Icons.notifications_none;
        color = BL.crimson;
    }
    return Semantics(
      label: '${n.isRead ? '' : 'New. '}${n.title}. ${n.body}',
      button: !n.isRead,
      child: InkWell(
        onTap: n.isRead ? null : () => NotificationService.markAsRead(n.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.isRead ? Colors.white : const Color(0xFFFDEEEE),
            border: const Border(bottom: BorderSide(color: BL.hairline)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(n.title,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 8),
                        Text(_ago(n.timestamp),
                            style:
                                const TextStyle(fontSize: 14, color: BL.muted)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: n.isRead ? BL.muted : BL.ink)),
                  ],
                ),
              ),
              if (!n.isRead)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: const BoxDecoration(
                      color: BL.crimson, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
