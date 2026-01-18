import 'package:flutter/services.dart'; // For rootBundle
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart'; // Import Added
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

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

  static const String _projectId = "buslink-416e1";
  // Generated from Firebase Console -> Project Settings -> Cloud Messaging -> Web Configuration
  static const String _vapidKey =
      "BMMQ7rRJHlKZ_-0CHE9LvFP4Vd5tarNDOx0loA7lraCOPmPOfvVEPCCxtrkyMa7Lc3iNEDuuCkxClMClEbSjPTE";

  // Loaded via Asset (Secure Option 2)
  static Future<String?> _getAccessToken() async {
    try {
      // 1. Load JSON from assets
      final jsonString =
          await rootBundle.loadString('assets/service_account.json');

      final serviceAccountMap = json.decode(jsonString);

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountMap);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final credentials = client.credentials;
      return credentials.accessToken.data;
    } catch (e) {
      debugPrint("Error getting access token (Asset Load): $e");
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
      if (kDebugMode) print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) print('User granted provisional permission');
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
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
              Icon(
                Icons.notifications_active,
                color: Colors.amber,
                size: 50,
              ),
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
      const projectId = _projectId;
      if (projectId.isEmpty) {
        debugPrint("FCM Error: Project ID not configured.");
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
    String type =
        'general', // Types: 'general', 'tripStatus', 'booking', 'delay', 'promotion'
    String? relatedId,
  }) async {
    // 1. Create Firestore Record (Always save to In-App History)
    await createNotification(
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId);

    // 2. Check User Preferences BEFORE sending Push
    try {
      final fs = FirestoreService();
      final prefs = await fs.getNotificationPreferences(userId);

      // Default to TRUE if prefs not set yet
      bool allowPush = true;

      if (prefs != null) {
        if (type == 'tripStatus' || type == 'delay') {
          allowPush = prefs['tripUpdates'] ?? true;
        } else if (type == 'booking') {
          allowPush = prefs['bookingConfirmations'] ?? true;
        } else if (type == 'promotion') {
          allowPush = prefs['promotions'] ?? true;
        } else if (type == 'reminder') {
          allowPush = prefs['reminders'] ?? true;
        } else if (type == 'duty') {
          allowPush = prefs['dutyAssignments'] ?? true;
        }
      }

      if (!allowPush) {
        if (kDebugMode)
          print("Push suppressed by user preference (Type: $type)");
        return;
      }

      // 3. Fetch Token & Send
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final token = data?['fcmToken'];
        if (token != null && token.toString().isNotEmpty) {
          await sendPushToToken(token.toString(), title, body);
        }
      }
    } catch (e) {
      debugPrint("Error in sendNotificationToUser: $e");
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
      // 1. Find all active bookings for trip
      final ticketsSnapshot = await FirebaseFirestore.instance
          .collection('tickets')
          .where('tripId', isEqualTo: tripId)
          .where('status', isEqualTo: 'confirmed')
          .get();

      if (ticketsSnapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      // 2. Loop passengers
      for (var doc in ticketsSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'];

        if (userId != null) {
          // Construct Message
          String title = 'Trip Update';
          String message = "Your trip ($routeName) is now $newStatus.";
          String type = 'tripStatus';

          if (newStatus == 'DELAYED') {
            title = "Trip Delayed";
            message =
                "Your trip ($routeName) is delayed by $delayMinutes mins.";
            type = 'delay';
          } else if (newStatus == 'CANCELLED') {
            title = "Trip Cancelled";
            message = "Urgent: Your trip ($routeName) has been cancelled.";
            type = 'tripStatus'; // Treated as update
          }

          // A. Create In-App Notification (Batch)
          final docRef =
              FirebaseFirestore.instance.collection('notifications').doc();
          batch.set(docRef, {
            'userId': userId,
            'title': title,
            'body': message,
            'type': type,
            'relatedId': tripId,
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
          });

          // B. Trigger Individual Send (Handles Pref Check internally)
          // Note: We can't batch 'sends' easily with individual pref checks in a loop efficiently without Logic.
          // Better: Fire and Forget the send so we don't block the batch commit?
          // Or just call the single method (which writes to Firestore again - DUPLICATE!)
          // Correct approach:
          // We already batched the "In-App" write above.
          // Now we just need the "Push" part.
          // Extract Push Logic to a helper function that checks prefs?

          // FAST FIX: Just call _checkAndSendPush independent of Firestore batch.
          _checkAndSendPush(userId, title, message, type);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint("Error in notifyTripStatusChange: $e");
    }
  }

  static Future<void> _checkAndSendPush(
      String userId, String title, String body, String type) async {
    try {
      final fs = FirestoreService();
      final prefs = await fs.getNotificationPreferences(userId);
      bool allowPush = true;
      if (prefs != null) {
        if (type == 'tripStatus' || type == 'delay')
          allowPush = prefs['tripUpdates'] ?? true;
      }

      if (!allowPush) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      final token = userDoc.data()?['fcmToken'];
      if (token != null) await sendPushToToken(token.toString(), title, body);
    } catch (e) {
      // Ignore
    }
  }

  /// Saves the FCM token to the user's Firestore profile
  static Future<void> saveTokenToUser(String userId) async {
    try {
      String? token;

      if (kIsWeb) {
        // REPLACE THIS WITH YOUR GENERATED KEY FROM FIREBASE CONSOLE
        token = await _firebaseMessaging.getToken(vapidKey: _vapidKey);
      } else {
        token = await _firebaseMessaging.getToken();
      }

      if (token != null) {
        if (kDebugMode) print("FCM Token: $token");

        // SUBSCRIBE TO TOPIC (Android/iOS only, Web requires Admin SDK)
        if (!kIsWeb) {
          await _firebaseMessaging.subscribeToTopic('app_promotion');
          if (kDebugMode) print("Subscribed to 'app_promotion' topic");
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
        }).catchError((e) {
          debugPrint("Error updating user token (doc might not exist): $e");
          FirebaseFirestore.instance.collection('users').doc(userId).set({
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
            'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          }, SetOptions(merge: true));
        });
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  /// Sends a TEST Topic Notification (Simulates Server)
  static Future<void> sendTestTopicNotification() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint("FCM Error: Could not get access token.");
        return;
      }

      // Construct Message with Platform Overrides
      final body = {
        "message": {
          "topic": "app_promotion",
          "notification": {
            "title": "A new app is available",
            "body": "Check out our latest app in the app store."
          },
          "android": {
            "notification": {
              "title": "A new Android app is available",
              "body": "Our latest app is available on Google Play store"
            }
          }
        }
      };

      final response = await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        debugPrint("Topic Message Sent Successfully: ${response.body}");
      } else {
        debugPrint(
            "Error sending Topic Message: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending test topic notification: $e");
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
