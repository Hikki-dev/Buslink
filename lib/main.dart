// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async'; // Added for Completer/Timer if needed

import 'firebase_options.dart';
import 'utils/platform/platform_utils.dart'; // Cross-platform utils

import 'controllers/trip_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'utils/notification_service.dart';
import 'utils/language_provider.dart';
import 'utils/translations.dart';
import 'utils/app_theme.dart';
import 'views/admin/admin_dashboard.dart';

import 'views/conductor/conductor_dashboard.dart';

import 'views/booking/payment_success_screen.dart';
import 'views/customer_main_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
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
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint("NotificationService init timed out - skipping");
          },
        );
        debugPrint("Notifications initialized");
      } catch (e) {
        debugPrint("Notification init failed: $e");
      }

      String? stripeKey;
      if (dotenv.isInitialized) {
        stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
      }

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
    } catch (e, stackTrace) {
      debugPrint("Unexpected initialization error: $e");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted && !_isInitialized) {
        setState(() {
          _isInitialized = true;
        });
        removeWebSpinner();
      }
    }
  }

  // Global Navigator Key for context-less navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Aggressive removal on build for web spinner
    removeWebSpinner();

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
          return Consumer<LanguageProvider>(
            builder: (context, languageProvider, _) {
              return MaterialApp(
                locale: Locale(languageProvider.currentLanguage),
                supportedLocales: const [
                  Locale('en'),
                  Locale('si'),
                  Locale('ta'),
                ],
                localizationsDelegates: const [
                  // Add flutter localizations delegates if needed, for now manual
                  // GlobalMaterialLocalizations.delegate,
                  // GlobalWidgetsLocalizations.delegate,
                  // GlobalCupertinoLocalizations.delegate,
                ],
                navigatorKey: _AppBootstrapperState.navigatorKey, // Assign Key
                title: 'BusLink',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeController.themeMode,
                // initialRoute: '/', // REMOVED: Let Flutter Web handle URL from browser
                routes: {
                  '/': (context) => const AuthWrapper(),
                },
                onGenerateRoute: (settings) {
                  // Handle deep link for payment success
                  if (settings.name?.startsWith('/payment_success') ?? false) {
                    return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => const PaymentSuccessScreen());
                  }
                  return null;
                },
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  // 1. LOADING SCREEN OVERLAY
                  if (!_isInitialized) {
                    return Scaffold(
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
                                Translations.translate(
                                    _statusKey, getPlatformLanguage()),
                                style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  // 2. CHILD (NAVIGATOR)
                  if (child == null) return const SizedBox();

                  // 3. GLOBAL ADMIN BANNER OVERLAY
                  final tripController = Provider.of<TripController>(context);

                  if (!tripController.isPreviewMode) {
                    return child;
                  }

                  return Column(
                    children: [
                      Material(
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          color: Colors.amber,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 16),
                          child: SafeArea(
                            bottom: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Welcome Admin - Preview Mode",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                        decoration: TextDecoration.none,
                                        fontSize: 14)),
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () async {
                                    // Update State
                                    await tripController.setPreviewMode(false);

                                    // Navigate using Global Key
                                    // We go to '/' which triggers AuthWrapper -> AdminDashboard
                                    _AppBootstrapperState
                                        .navigatorKey.currentState
                                        ?.pushNamedAndRemoveUntil(
                                            '/', (route) => false);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Text("EXIT",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: child),
                    ],
                  );
                },
              );
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
      // Lazy Login: Allow guests to see the main screen
      return const CustomerMainScreen();
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

  Future<DocumentSnapshot> _fetchUserData() async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    // GUEST MODE CHECK
    if (widget.user.isAnonymous) {
      return await firestoreService.getUserData(widget.user.uid);
    }

    try {
      final result =
          await firestoreService.getUserData(widget.user.uid).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw "Firestore Timeout";
        },
      );
      return result;
    } catch (e) {
      rethrow;
    }
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
    if (widget.user.isAnonymous) {
      return const CustomerMainScreen();
    }

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
          return const CustomerMainScreen();
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
          return const CustomerMainScreen();
        }

        final String role = (data['role'] ?? 'customer').toString().trim();
        debugPrint("User: ${widget.user.email} (UID: ${widget.user.uid})");
        debugPrint("Firestore Data: $data");
        debugPrint("Determined Role: $role");

        // Last chance to remove spinner
        removeWebSpinner();

        switch (role) {
          case 'admin':
            return const AdminDashboard();
          case 'conductor':
            return const ConductorDashboard();

          case 'customer':
          default:
            return const CustomerMainScreen();
        }
      },
    );
  }
}
