// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async'; // Added for Completer/Timer if needed

import 'firebase_options.dart';
import 'utils/platform/platform_utils.dart'; // Cross-platform utils
import 'services/cache_service.dart';

import 'controllers/trip_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/notification_service.dart';
import 'services/trip_reminder_service.dart'; // Added Import
import 'utils/language_provider.dart';
import 'utils/translations.dart';
import 'utils/app_theme.dart';
import 'views/admin/admin_dashboard.dart';

import 'views/conductor/conductor_dashboard.dart';

import 'views/booking/payment_success_screen.dart';
import 'views/customer_main_screen.dart';
import 'views/auth/login_screen.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  debugPrint("🚀 APP STARTUP: Version with Safer Spinner Removal 🚀");
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
  AuthService? _authService;

  String? _cachedRole;

  @override
  void initState() {
    super.initState();
    _startBootSequence();
  }

  Future<void> _startBootSequence() async {
    // 0. Cache Fast Load
    try {
      // Smallest possible delay to let UI mount
      await CacheService().init();
      final cachedProfile = CacheService().getUserProfile();

      if (cachedProfile != null && mounted) {
        // OPTIMISTIC START: We found a user in cache!
        // Show UI immediately while Firebase connects
        setState(() {
          _cachedRole = cachedProfile['role'];
          _isInitialized = true; // Show UI!
        });
        removeWebSpinner();
        debugPrint("🚀 OPTIMISTIC CROW: Booting as $_cachedRole");
      }
    } catch (e) {
      debugPrint("Cache init error: $e");
    }

    // Continue with real initialization (Background if optimistic)
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1. Load Env (Fast) - Critical for other steps
      await dotenv.load(fileName: ".env");

      // 2. Firebase Init
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 3. Enable Firestore Persistence (Offline Capabilities)
      FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);

      _authService = AuthService();

      // 4. Non-Critical Services (Fire & Forget)
      // Running these without await to unblock UI immediately
      Future.wait([
        NotificationService.initialize()
            .catchError((e) => debugPrint("Notification Init Error: $e")),
        _initStripe().catchError((e) => debugPrint("Stripe Init Error: $e")),
        _initAuth().catchError((e) => debugPrint("Auth Init Error: $e")),
      ]);
    } catch (e, stackTrace) {
      debugPrint("Init Error: $e");
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        removeWebSpinner();
      }
    }
  }

  Future<void> _initStripe() async {
    // ... stripe logic extracted ...
    String? stripeKey;
    if (dotenv.isInitialized) {
      stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
    }
    if (stripeKey != null) {
      stripe.Stripe.publishableKey = stripeKey;
      await stripe.Stripe.instance.applySettings();
    }
  }

  Future<void> _initAuth() async {
    if (_authService != null) {
      await _authService!.initializeGoogleSignIn();
    }
  }

  // Global Navigator Key
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    removeWebSpinner();

    return MultiProvider(
      providers: [
        Provider<AuthService>(
            create: (_) =>
                _authService ??
                AuthService()), // Fallback if _authService not set yet
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (context) {
            // If authService isn't ready, we might return null stream?
            // But we initialized it in _initialize() at step 2.
            // If Optimistic, _authService might be null for a few ms until _initialize hits step 2.
            // We should be careful.
            if (_authService == null) return const Stream.empty();
            return context.read<AuthService>().user;
          },
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
                // ... props ...
                locale: Locale(languageProvider.currentLanguage),
                supportedLocales: const [
                  Locale('en'),
                  Locale('si'),
                  Locale('ta')
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                navigatorKey: _AppBootstrapperState.navigatorKey,
                title: 'BusLink',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeController.themeMode,
                routes: {
                  '/': (context) => const AuthWrapper(),
                  '/login': (context) => const LoginScreen(),
                },
                onGenerateRoute: (settings) {
                  if (settings.name?.startsWith('/payment_success') ?? false) {
                    return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => const PaymentSuccessScreen());
                  }
                  return null;
                },
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  // 1. LOADING SCREEN (Only if NOT Initialized)
                  if (!_isInitialized) {
                    return Scaffold(
                      backgroundColor: Theme.of(context)
                          .scaffoldBackgroundColor, // Theme aware
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // 1. BRAND LOGO
                            Icon(Icons.directions_bus,
                                size: 80,
                                color: Theme.of(context).primaryColor),
                            const SizedBox(height: 16),
                            // 2. BRAND NAME
                            Text(
                              "BusLink",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).primaryColor,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 40),
                            // 3. MINIMALIST LOADER
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // 2. OPTIMISTIC / REAL CHILD
                  // If we are optimized/booted, we show 'child'.
                  // BUT 'child' is the Navigator, which routes to '/'.
                  // '/' is AuthWrapper.
                  // AuthWrapper relies on StreamProvider<User?>.
                  // If Firebase is connecting, Stream<User?> is Empty or Null.
                  // So AuthWrapper sees null user -> renders CustomerMainScreen.
                  // If cachedRole was Admin, we want AdminScreen!

                  // WE NEED to inject the Cached Role into AuthWrapper or handle it here?
                  // Easier: Pass cachedRole to AuthWrapper via Provider or a wrapping widget?
                  // OR: Handle Optimistic Overlay here?

                  // Let's modify AuthWrapper to use CacheService as fallback!

                  return child!;
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
    // 1. Real Match
    final user = Provider.of<User?>(context);
    if (user != null) {
      return RoleDispatcher(user: user);
    }

    // 2. Cache Fallback (Optimistic)
    final cachedProfile = CacheService().getUserProfile();
    if (cachedProfile != null) {
      final role = cachedProfile['role'];
      switch (role) {
        case 'admin':
          return const AdminDashboard();
        case 'conductor':
          return const ConductorDashboard();
      }
    }

    // 3. Guest / Default -> Force Login
    return const LoginScreen();
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
  TripReminderService? _reminderService;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
    _startReminderService();
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
    _reminderService?.stop();
    super.dispose();
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
      _startReminderService();
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

        // Save FCM Token
        NotificationService.saveTokenToUser(widget.user.uid);

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
