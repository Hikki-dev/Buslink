import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/cache_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/trip_reminder_service.dart';
import '../utils/app_theme.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/auth/login_screen.dart';
import '../views/conductor/conductor_dashboard.dart';
import '../views/customer_main_screen.dart';
import '../views/splash/splash_screen.dart';
import 'background_services.dart';

/// Signed in: go to the right home screen. Signed out: the sign-in page.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user != null) return RoleDispatcher(user: user);
    return const LoginScreen();
  }
}

/// Looks up the signed-in person's role and shows the matching home screen:
/// admin, conductor or passenger.
///
/// The role is remembered on this device, so a returning person goes straight
/// to their home screen while the lookup runs, instead of waiting at a loading
/// screen. If the lookup disagrees (for example an admin made them a
/// conductor), the screen switches.
class RoleDispatcher extends StatefulWidget {
  const RoleDispatcher({super.key, required this.user});

  final User user;

  @override
  State<RoleDispatcher> createState() => _RoleDispatcherState();
}

class _RoleDispatcherState extends State<RoleDispatcher> {
  late Future<DocumentSnapshot> _userFuture;
  TripReminderService? _reminderService;
  StreamSubscription? _messages;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
    _startReminderService();

    // Show push messages that arrive while the app is open, as a banner.
    _messages = foregroundMessages.listen((message) {
      final notification = message.notification;
      if (!mounted || notification == null) return;
      if (notification.title != null && notification.body != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'View', onPressed: () {}),
          ),
        );
      }
    });
  }

  void _startReminderService() {
    _reminderService?.stop();
    if (!widget.user.isAnonymous) {
      _reminderService = TripReminderService(widget.user.uid);
      _reminderService!.start();
    }
  }

  @override
  void dispose() {
    _messages?.cancel();
    _reminderService?.stop();
    super.dispose();
  }

  Future<DocumentSnapshot> _fetchUserData() async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    if (widget.user.isAnonymous) {
      return firestoreService.getUserData(widget.user.uid);
    }

    final snapshot = await firestoreService
        .getUserData(widget.user.uid)
        .timeout(const Duration(seconds: 5),
            onTimeout: () => throw 'Firestore Timeout');
    _remember(snapshot);
    return snapshot;
  }

  /// Remembers this person's role on the device for the next launch.
  void _remember(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    final role = data?['role'];
    if (role is String && role.trim().isNotEmpty) {
      CacheService()
          .saveUserProfile({'uid': widget.user.uid, 'role': role.trim()});
    }
  }

  /// The home screen for the role remembered on this device, if it is for
  /// this person.
  Widget? _rememberedHome() {
    final saved = CacheService().getUserProfile();
    if (saved == null || saved['uid'] != widget.user.uid) return null;
    return _homeFor((saved['role'] ?? 'customer').toString());
  }

  static Widget _homeFor(String role) {
    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'conductor':
        return const ConductorDashboard();
      default:
        return const CustomerMainScreen();
    }
  }

  @override
  void didUpdateWidget(RoleDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _userFuture = _fetchUserData();
      _startReminderService();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.isAnonymous) return const CustomerMainScreen();

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _rememberedHome() ??
              const SplashScreen(
                  status: 'Loading your profile', playIntro: false);
        }
        if (snapshot.hasError) {
          debugPrint('Could not read the profile: ${snapshot.error}');
          // Offline, for example: fall back to the passenger home.
          return const CustomerMainScreen();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint(
              'User document missing for ${widget.user.uid}: creating it.');
          // Self-healing: create the profile the person should have had.
          final role =
              (widget.user.email == 'admin@buslink.com') ? 'admin' : 'customer';
          firestoreService.createUserProfile({
            'uid': widget.user.uid,
            'email': widget.user.email,
            'displayName': widget.user.displayName ??
                widget.user.email?.split('@')[0] ??
                'User',
            'role': role,
            'createdAt': FieldValue.serverTimestamp(),
          });
          return const SplashScreen(
              status: 'Creating your profile', playIntro: false);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        // The master admin email always gets the admin role.
        if (widget.user.email == 'admin@buslink.com' &&
            data?['role'] != 'admin') {
          firestoreService.updateUserRole(widget.user.uid, 'admin');
          return const SplashScreen(
              status: 'Updating admin access', playIntro: false);
        }

        if (data == null) return const CustomerMainScreen();

        final role = (data['role'] ?? 'customer').toString().trim();

        // Ask to send notifications (Android 13+, iOS) and save this device's
        // push token, once the role is known.
        if (!const bool.fromEnvironment('IS_TESTING')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NotificationService.requestPermissionWithDialog(context);
          });
          NotificationService.saveTokenToUser(widget.user.uid);
        }

        return _homeFor(role);
      },
    );
  }
}
