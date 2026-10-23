import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:rxdart/rxdart.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Messages that arrive while the app is open. The signed-in home screen
/// listens to this and shows them as a banner.
final BehaviorSubject<RemoteMessage> foregroundMessages =
    BehaviorSubject<RemoteMessage>();

/// Work that can wait until the first screen is showing: push notifications,
/// Stripe and Google sign-in. None of it is needed to draw the first screen, so
/// none of it is allowed to slow that down. A failure in one is logged and
/// does not affect the others.
class BackgroundServices {
  const BackgroundServices._();

  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  static bool _started = false;

  static const bool _isTesting = bool.fromEnvironment('IS_TESTING');

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
  );

  /// Starts everything once. Calling it again does nothing.
  static Future<void> start(AuthService auth) async {
    if (_started) return;
    _started = true;
    await Future.wait([
      _task('local notifications', _setUpLocalNotifications),
      _task('push notifications', NotificationService.initialize),
      _task('stripe', _setUpStripe),
      _task('google sign-in', auth.initializeGoogleSignIn),
    ]);
  }

  static Future<void> _task(String name, Future<void> Function() run) async {
    try {
      await run();
    } catch (e) {
      debugPrint('Background service "$name" failed: $e');
    }
  }

  static Future<void> _setUpLocalNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    if (!_isTesting) {
      await _local.initialize(settings);
    } else {
      debugPrint('Skipping local notifications: IS_TESTING is set.');
    }

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // While the app is open, show a banner for every push message.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      foregroundMessages.sink.add(message);

      final notification = message.notification;
      final android = notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        _local.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });
  }

  static Future<void> _setUpStripe() async {
    if (!dotenv.isInitialized) return;
    final key = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    if (key == null || key.isEmpty) return;
    stripe.Stripe.publishableKey = key;
    await stripe.Stripe.instance.applySettings();
  }
}
