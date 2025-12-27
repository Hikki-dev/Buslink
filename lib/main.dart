// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/trip_controller.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'utils/app_theme.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/auth/login_screen.dart';
import 'views/conductor/conductor_dashboard.dart';
import 'views/home/home_screen.dart';
import 'views/booking/payment_success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Failed to load .env file: $e");
  }

  // Initialize Stripe
  // You must set your publishable key in your .env file
  // STRIPE_PUBLISHABLE_KEY=pk_test_...
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (stripeKey != null) {
    try {
      stripe.Stripe.publishableKey = stripeKey;
      await stripe.Stripe.instance.applySettings();
    } catch (e) {
      debugPrint("Warning: Failed to initialize Stripe: $e");
    }
  } else {
    debugPrint("STRIPE_PUBLISHABLE_KEY not found in .env");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Critical: Firebase initialization failed: $e");
    // We continue, but app might be broken.
  }

  // Initialize Google Sign-In
  final authService = AuthService();
  try {
    await authService.initializeGoogleSignIn();
  } catch (e) {
    debugPrint("Warning: Google Sign-In init failed: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => TripController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
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
              // Handle deep links or manual URL typing if needed
              if (settings.name?.startsWith('/payment_success') ?? false) {
                return MaterialPageRoute(
                    builder: (_) => const PaymentSuccessScreen());
              }
              return null;
            },
          );
        },
      ),
    ),
  );
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
class RoleDispatcher extends StatelessWidget {
  final User user;
  const RoleDispatcher({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return FutureBuilder<DocumentSnapshot>(
      future: firestoreService.getUserData(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          debugPrint("!!! FIRESTORE ERROR: ${snapshot.error}");
          return const Scaffold(
              body: Center(child: Text("Database Error. Check Console.")));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint(
              "!!! USER DOCUMENT MISSING (UID: ${user.uid}) - Attempting Self-Healing");

          // --- SELF-HEALING: Create the missing doc ---
          firestoreService.createUserProfile({
            'uid': user.uid,
            'email': user.email,
            'displayName':
                user.displayName ?? user.email?.split('@')[0] ?? 'User',
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Show a temporary loading or fallback while it creates
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          debugPrint(
              "User detected (UID: ${user.uid}) but NO DATA in Firestore 'users' collection.");
          return const HomeScreen();
        }

        final String role = (data['role'] ?? 'customer').toString().trim();
        debugPrint("User: ${user.email} (UID: ${user.uid})");
        debugPrint("Firestore Data: $data");
        debugPrint("Determined Role: $role");

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
