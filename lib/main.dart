// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:html'
    as html; // ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'controllers/trip_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'utils/notification_service.dart';
import 'utils/language_provider.dart';
import 'utils/translations.dart';
import 'utils/app_theme.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/auth/login_screen.dart';
import 'views/conductor/conductor_dashboard.dart';
import 'views/home/home_screen.dart';
import 'views/booking/payment_success_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppBootstrapper());
}

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper> {
  bool _isInitialized = false;
  String _statusKey = "booting"; // Debug status
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Safety timeout to ensure app ALWAYS loads eventually
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isInitialized) {
        debugPrint("Force-loading app due to initialization timeout");
        setState(() {
          _isInitialized = true;
          _statusKey = "timeout_load";
        });
      }
    });

    try {
      // 1. Load Env
      try {
        setState(() => _statusKey = "loading_env");
        await dotenv.load(fileName: ".env");
        debugPrint("Env loaded");
      } catch (e) {
        debugPrint("Warning: Failed to load .env file: $e");
      }

      // 2. Firebase
      try {
        setState(() => _statusKey = "connecting_firebase");
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint("Firebase initialized");
        // Initialize Auth Service early so it's ready if timeout triggers
        _authService = AuthService();
      } catch (e) {
        debugPrint("Critical: Firebase initialization failed: $e");
      }

      // 3. Status Check & Notifications
      setState(() => _statusKey = "init_services");

      try {
        await NotificationService.initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint("NotificationService init timed out - skipping");
          },
        );
        debugPrint("Notifications initialized");
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }

      final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      if (stripeKey != null) {
        try {
          stripe.Stripe.publishableKey = stripeKey;
          await stripe.Stripe.instance.applySettings().timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              debugPrint("Stripe init timed out - skipping");
            },
          );
          debugPrint("Stripe initialized");
        } catch (e) {
          debugPrint("Warning: Failed to initialize Stripe: $e");
        }
      }

      // 4. Auth (Actions that require async setup, service already instanced)
      setState(() => _statusKey = "init_auth");
      try {
        if (_authService != null) {
          await _authService!
              .initializeGoogleSignIn()
              .timeout(const Duration(seconds: 3), onTimeout: () {
            debugPrint("Google Sign-In init timed out - skipping");
          });
          debugPrint("Google Sign-In initialized");
        }
      } catch (e) {
        debugPrint("Warning: Google Sign-In init failed: $e");
      }
    } catch (e) {
      debugPrint("Unexpected initialization error: $e");
    } finally {
      if (mounted && !_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
        _removeHtmlSpinner();
      }
    }
  }

  void _removeHtmlSpinner() {
    try {
      final loader = html.document.getElementById('loading-indicator');
      if (loader != null) {
        loader.remove();
        debugPrint("Deleted HTML Spinner via Dart");
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    // Aggressive removal on build
    _removeHtmlSpinner();

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bus,
                    size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                    color: AppTheme.primaryColor, strokeWidth: 6),
                const SizedBox(height: 16),
                Text(
                    Translations.translate(_statusKey,
                        html.window.navigator.language.split('-')[0]),
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)), // Status Text
              ],
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => _authService!),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => TripController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: 'BusLink',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            home: const AuthWrapper(),
            routes: {
              '/payment_success': (context) => const PaymentSuccessScreen(),
            },
            debugShowCheckedModeBanner: false,
            onGenerateRoute: (settings) {
              if (settings.name?.startsWith('/payment_success') ?? false) {
                return MaterialPageRoute(
                    settings: settings,
                    builder: (_) => const PaymentSuccessScreen());
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

// AuthWrapper (MODIFIED)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user == null) {
      return const LoginScreen();
    } else {
      return RoleDispatcher(user: user);
    }
  }
}

// NEW WIDGET: RoleDispatcher
class RoleDispatcher extends StatefulWidget {
  final User user;
  const RoleDispatcher({super.key, required this.user});

  @override
  State<RoleDispatcher> createState() => _RoleDispatcherState();
}

class _RoleDispatcherState extends State<RoleDispatcher> {
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  Future<DocumentSnapshot> _fetchUserData() {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    return firestoreService.getUserData(widget.user.uid).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        throw "Firestore Timeout";
      },
    );
  }

  @override
  void didUpdateWidget(RoleDispatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.uid != widget.user.uid) {
      _userFuture = _fetchUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                      Translations.translate(
                          'loading_profile',
                          Provider.of<LanguageProvider>(context)
                              .currentLanguage),
                      style: const TextStyle(color: Colors.grey, fontSize: 18))
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint("!!! FIRESTORE ERROR: ${snapshot.error}");
          // Fallback to Home if Firestore fails (Offline mode potentially)
          return const HomeScreen();
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint(
              "!!! USER DOCUMENT MISSING (UID: ${widget.user.uid}) - Attempting Self-Healing");

          // --- SELF-HEALING: Create the missing doc ---
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

          return const Scaffold(
              body: Center(child: Text("Creating Profile...")));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        // Force Admin Role if it's the master email but has wrong role
        if (widget.user.email == 'admin@buslink.com' &&
            data?['role'] != 'admin') {
          firestoreService.updateUserRole(widget.user.uid, 'admin');
          return const Scaffold(
              body: Center(child: Text("Updating Admin Access...")));
        }

        if (data == null) {
          return const HomeScreen();
        }

        final String role = (data['role'] ?? 'customer').toString().trim();
        debugPrint("User: ${widget.user.email} (UID: ${widget.user.uid})");
        debugPrint("Firestore Data: $data");
        debugPrint("Determined Role: $role");

        // Last chance to remove spinner
        try {
          final loader = html.document.getElementById('loading-indicator');
          if (loader != null) {
            loader.remove();
            debugPrint("Deleted HTML Spinner via RoleDispatcher");
          }
        } catch (e) {}

        switch (role) {
          case 'admin':
            return const AdminDashboard();
          case 'conductor':
            return const ConductorDashboard();
          case 'customer':
          default:
            return const HomeScreen();
        }
      },
    );
  }
}
