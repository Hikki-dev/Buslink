import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Added for Dialogs
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../models/notification_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ... (keep existing)
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // ... (keep initialize method same)
  static Future<void> initialize() async {
    // 1. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Setup Foreground Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
    });

    // 3. Check current status (don't request yet)
    // NotificationSettings settings = await _firebaseMessaging.getNotificationSettings();
    // if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    //   await _setupToken();
    // }
  }

  /// UX-Friendly Permission Request
  static Future<void> requestPermissionWithDialog(BuildContext context) async {
    NotificationSettings settings =
        await _firebaseMessaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Already authorized, ensure token is synced
      await _setupToken();
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      // Already denied, maybe show instructions to enable in settings?
      return;
    }

    // Show "Why we need this" Dialog
    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Stay Updated"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/notification_bell.png',
                  height: 60,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.notifications_active,
                      size: 50,
                      color: Colors.amber)),
              const SizedBox(height: 16),
              const Text(
                "We need to send you notifications for:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("• Trip Delays & Status Updates"),
              const Text("• Booking Confirmations"),
              const Text("• Refund Status"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _triggerSystemRequest();
              },
              child: const Text("Allow Notifications"),
            ),
          ],
        ),
      );
    }
  }

  static Future<void> _triggerSystemRequest() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
      await _setupToken();
    }
  }

  static Future<void> _setupToken() async {
    // ... (keep token logic same)
    if (!kIsWeb && Platform.isIOS) {
      // ... existing logic ...
      String? apnsToken;
      try {
        apnsToken = await _firebaseMessaging.getAPNSToken();
      } catch (e) {
        // Ignore initial APNS error
      }
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          apnsToken = await _firebaseMessaging.getAPNSToken();
        } catch (e) {
          debugPrint("Failed to get APNS token: $e");
        }
      }
      if (apnsToken == null) return;
    }

    // Get the token (Web VAPID Key if needed, but standard usually works if config is good)
    // For specific VAPID: getToken(vapidKey: "YOUR_PUBLIC_KEY")
    final fcmToken = await _firebaseMessaging.getToken(
        vapidKey:
            kIsWeb ? "BOyF-..." : null // Optional: Add VAPID if default fails
        );
    if (kDebugMode) print("FCM Token: $fcmToken");
  }

  /// Streams notifications for a specific user
  static Stream<List<AppNotification>> getUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc))
            .toList());
  }

  /// Mark a notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error marking all as read: $e");
    }
  }

  // --- NEW: Sprint 3 Notification Logic ---

  /// Creates a notification in Firestore for a specific user
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      if (kDebugMode) {
        print("Notification created for user: $userId");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error creating notification: $e");
      }
    }
  }

  /// Notifies all passengers of a trip about a status change
  static Future<void> notifyTripStatusChange(
      String tripId, String routeName, String newStatus,
      {int delayMinutes = 0}) async {
    try {
      if (kDebugMode) {
        print("Notifying passengers for trip $tripId: Status $newStatus");
      }
      // 1. Find all active bookings (tickets) for this trip
      final ticketsSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('tripId', isEqualTo: tripId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (ticketsSnapshot.docs.isEmpty) {
        if (kDebugMode) print("No passengers to notify for trip $tripId");
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      // 2. batch create notifications
      for (var doc in ticketsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'];

        if (userId != null) {
          final docRef =
              FirebaseFirestore.instance.collection('notifications').doc();

          String title = 'Trip Update: $newStatus';
          String message = "Your trip ($routeName) is now $newStatus.";
          String type = 'tripStatus'; // Default

          if (newStatus == 'DELAYED') {
            title = "Trip Delayed";
            message =
                "Heads up! Your trip ($routeName) is delayed by $delayMinutes minutes.";
            type = 'delay';
          } else if (newStatus == 'DEPARTED') {
            title = "Bus Departed";
            message = "Your bus ($routeName) has departed!";
            type = 'tripStatus';
          } else if (newStatus == 'ARRIVED') {
            title = "Arrived";
            message = "You have arrived at your destination ($routeName).";
            type = 'tripStatus';
          } else if (newStatus == 'CANCELLED') {
            title = "Trip Cancelled";
            message = "Urgent: Your trip ($routeName) has been cancelled.";
            type = 'cancellation';
          }

          batch.set(docRef, {
            'userId': userId,
            'title': title,
            'body': message,
            'type': type,
            'relatedId': tripId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });
        }
      }

      await batch.commit();
      if (kDebugMode) {
        print(
            "Notifications sent to ${ticketsSnapshot.docs.length} passengers.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error in notifyTripStatusChange: $e");
      }
    }
  }

  /// Saves the FCM token to the user's Firestore profile
  static Future<void> saveTokenToUser(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token == null) return;

      // Robustly save token (Array or Single Field?)
      // Single field is easier for 1-1 deviceness, Array is better for multi-device.
      // Let's use specific field for now or Merge.
      // We will do both: 'fcmToken' (last used) and add to 'fcmTokens' array.

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userRef.set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print("FCM Token saved for user $userId");
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }
}
