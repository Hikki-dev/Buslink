import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../models/notification_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();

  // Credentials provided by user (BusLink Service Account)
  // TODO: IMPORTANT - Replace this with your actual service account JSON for local testing.
  // DO NOT COMMIT REAL CREDENTIALS TO GIT.
  // Ideally, move this logic to a backend server.
  static const Map<String, dynamic> _serviceAccountJson = {
    "type": "service_account",
    "project_id": "buslink-416e1",
    // ... Add your real credentials here locally ...
  };

  static Future<String?> _getAccessToken() async {
    try {
      final accountCredentials =
          ServiceAccountCredentials.fromJson(_serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final credentials = client.credentials; // Not a future
      return credentials.accessToken.data;
    } catch (e) {
      debugPrint("Error getting access token: $e");
      return null;
    }
  }

  static Future<void> initialize() async {
    // 0. Initialize Local Notifications
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings();

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(initializationSettings);

    // 1. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Setup Foreground Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }
    });
  }

  /// UX-Friendly Permission Request
  static Future<void> requestPermissionWithDialog(BuildContext context) async {
    NotificationSettings settings =
        await _firebaseMessaging.getNotificationSettings();

    // Android 13+ Local Notification Permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _setupToken();
      return;
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

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
    if (!kIsWeb && Platform.isIOS) {
      String? apnsToken;
      try {
        apnsToken = await _firebaseMessaging.getAPNSToken();
      } catch (e) {
        // Ignore initial check
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

    final fcmToken = await _firebaseMessaging.getToken(
        vapidKey: kIsWeb
            ? "BOyF-..." // User would need to fill this if web push is needed, but focusing on mobile
            : null);
    if (kDebugMode) print("FCM Token: $fcmToken");

    // Save token if user is logged in? Usually we do this explicitly when user logs in or profile loads.
    // Ideally we pass current user ID here if available, but for now we rely on saveTokenToUser usage.
  }

  /// Sends a push notification via FCM HTTP v1 API
  static Future<void> sendPushToToken(
      String token, String title, String body) async {
    try {
      final projectId = _serviceAccountJson['project_id'];
      if (projectId == 'YOUR_PROJECT_ID') {
        debugPrint("FCM Error: Service Account not configured.");
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) return;

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(
          <String, dynamic>{
            'message': <String, dynamic>{
              'token': token,
              'notification': <String, dynamic>{
                'body': body,
                'title': title,
              },
              'data': <String, dynamic>{
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'status': 'done'
              },
              'android': {
                'priority': 'HIGH',
              }
            },
          },
        ),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) print("Push notification sent to $token");
      } else {
        if (kDebugMode)
          print(
              "Failed to send push: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending push: $e");
      }
    }
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

  /// Sends a Push Notification AND creates a Firestore record
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String type = 'general',
    String? relatedId,
  }) async {
    // 1. Create Firestore Record (In-App)
    await createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId);

    // 2. Fetch User Token
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final token = data?['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          // 3. Send FCM Push
          await sendPushToToken(token.toString(), title, body);
        } else {
          debugPrint("No FCM token found for user $userId");
        }
      }
    } catch (e) {
      debugPrint("Error fetching user token for push: $e");
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

      // 2. batch create notifications & Send Pushes
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

          // A. Add to In-App Notifications
          batch.set(docRef, {
            'userId': userId,
            'title': title,
            'body': message,
            'type': type,
            'relatedId': tripId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          // B. Send Push Notification (Fire & Forget)
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get()
              .then((userDoc) {
            if (userDoc.exists) {
              final userData = userDoc.data();
              // Try 'fcmToken' first, if likely simple string
              // In saveTokenToUser, we save both.
              final token = userData?['fcmToken'];
              if (token != null && token.toString().isNotEmpty) {
                sendPushToToken(token.toString(), title, message);
              }
            }
          });
        }
      }

      await batch.commit();
      if (kDebugMode) {
        print(
            "Notifications processed for ${ticketsSnapshot.docs.length} passengers.");
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

  static Future<void> scheduleTripReminder(
      int id, String title, String body, DateTime scheduledDate) async {
    try {
      tz.initializeTimeZones();

      if (scheduledDate.isBefore(DateTime.now())) return;

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const fln.NotificationDetails(
          android: fln.AndroidNotificationDetails(
            'trip_reminders',
            'Trip Reminders',
            channelDescription: 'Notifications for upcoming trips',
            importance: fln.Importance.max,
            priority: fln.Priority.high,
          ),
          iOS: fln.DarwinNotificationDetails(),
        ),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation removed as it is reported undefined
      );
      if (kDebugMode) {
        print("Scheduled reminder '$title' for $scheduledDate (ID: $id)");
      }
    } catch (e) {
      debugPrint("Error scheduling reminder: $e");
    }
  }
}
