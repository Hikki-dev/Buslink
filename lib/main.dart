import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart'; // Uncomment when Firebase is configured

import 'controllers/trip_controller.dart';
import 'views/home/home_screen.dart';
import 'utils/app_theme.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==================== FIREBASE INITIALIZATION ====================
  // Uncomment after running: flutterfire configure
  // try {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //   debugPrint('✅ Firebase initialized successfully');
  // } catch (e) {
  //   debugPrint('❌ Firebase initialization failed: $e');
  //   debugPrint('📱 Running in DEMO MODE with mock data');
  // }

  runApp(const BusLinkApp());
}

/// Main App Widget
class BusLinkApp extends StatelessWidget {
  const BusLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Main controller for trip management
        ChangeNotifierProvider(create: (_) => TripController()),
        // Add more controllers here as needed:
        // ChangeNotifierProvider(create: (_) => AuthController()),
        // ChangeNotifierProvider(create: (_) => BookingController()),
      ],
      child: MaterialApp(
        // ==================== APP CONFIGURATION ====================
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // ==================== THEME ====================
        theme: AppTheme.lightTheme,

        // ==================== HOME SCREEN ====================
        home: const HomeScreen(),

        // ==================== NAVIGATION ====================
        // You can add named routes here for cleaner navigation
        // routes: {
        //   '/home': (context) => const HomeScreen(),
        //   '/search': (context) => const BusListScreen(),
        //   '/details': (context) => const BusDetailsScreen(),
        //   '/booking': (context) => const SeatSelectionScreen(),
        //   '/ticket': (context) => const TicketScreen(),
        //   '/admin': (context) => const AdminDashboard(),
        // },
      ),
    );
  }
}
