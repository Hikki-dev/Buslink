import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class TripReminderService {
  Timer? _timer;
  final String userId;

  TripReminderService(this.userId);

  /// Starts the periodic check for trip reminders
  void start() {
    _checkReminders(); // Run immediately
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkReminders();
    });
    debugPrint("TripReminderService started for user: $userId");
  }

  /// Stops the service
  void stop() {
    _timer?.cancel();
    debugPrint("TripReminderService stopped");
  }

  Future<void> _checkReminders() async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Fetch active confirmed tickets for the user
      final snapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String ticketId = doc.id;
        final String routeName = data['routeName'] ?? 'Bus Trip';
        final String tripId = data['tripId'] ?? '';

        if (data['departureTimestamp'] == null) {
          // Fallback or skip if timestamp isn't stored.
          // In a real app we might try to reconstruct from strings, but for now we rely on the timestamp
          // which should be set during booking creation.
          continue;
        }

        final tripDateTime = (data['departureTimestamp'] as Timestamp).toDate();

        final difference = tripDateTime.difference(now);
        final inHours = difference.inHours;
        final inMinutes = difference.inMinutes;

        // 1. Check 24 Hour Reminder (Between 23 and 25 hours)
        if (inHours >= 23 && inHours <= 25) {
          final key = 'sent_24h_$ticketId';
          if (!prefs.containsKey(key)) {
            await NotificationService.createNotification(
              userId: userId,
              title: "Trip Reminder",
              body: "Your trip to $routeName is in 24 hours.",
              type: "tripStatus",
              relatedId: tripId,
            );
            await prefs.setBool(key, true);
            debugPrint("Sent 24h reminder for ticket $ticketId");
          }
        }

        // 2. Check 1 Hour Reminder (Between 45 and 75 minutes)
        if (inMinutes >= 45 && inMinutes <= 75) {
          final key = 'sent_1h_$ticketId';
          if (!prefs.containsKey(key)) {
            await NotificationService.createNotification(
              userId: userId,
              title: "Trip Departing Soon!",
              body:
                  "Your trip to $routeName departs in about an hour. Don't be late!",
              type: "tripStatus",
              relatedId: tripId,
            );
            await prefs.setBool(key, true);
            debugPrint("Sent 1h reminder for ticket $ticketId");
          }
        }
      }
    } catch (e) {
      debugPrint("Error in TripReminderService: $e");
    }
  }
}
