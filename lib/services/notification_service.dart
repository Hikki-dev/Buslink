import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
    // requesting permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
    }

    // ... (keep token logic same)
    if (!kIsWeb && Platform.isIOS) {
      // ... existing logic ...
      String? apnsToken;
      try {
        apnsToken = await _firebaseMessaging.getAPNSToken();
      } catch (e) {}
      if (apnsToken == null) {
        await Future.delayed(const Duration(seconds: 3));
        try {
          apnsToken = await _firebaseMessaging.getAPNSToken();
        } catch (e) {}
      }
      if (apnsToken == null) return;
    }

    // Get the token
    final fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) print("FCM Token: $fcmToken");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
    });
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
      String tripId, String routeName, String newStatus) async {
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

          String message = "Your trip ($routeName) is now $newStatus.";
          if (newStatus == 'DELAYED') {
            message = "Heads up! Your trip ($routeName) is delayed.";
          } else if (newStatus == 'DEPARTED') {
            message = "Your bus ($routeName) has departed!";
          } else if (newStatus == 'ARRIVED') {
            message = "You have arrived at your destination ($routeName).";
          } else if (newStatus == 'CANCELLED') {
            message = "Urgent: Your trip ($routeName) has been cancelled.";
          }

          batch.set(docRef, {
            'userId': userId,
            'title': 'Trip Status: $newStatus',
            'body': message,
            'type': 'trip_update',
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
