// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- IMPORT
import 'firebase_options.dart'; // <-- IMPORT THE FILE YOU GENERATED
import 'controllers/trip_controller.dart';
import 'utils/app_theme.dart';
import 'views/home/home_screen.dart';

void main() async {
  // --- THIS IS THE FIX ---
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Failed to initialize Firebase: $e");
    // Handle initialization error
  }
  // -------------------------

  runApp(
    ChangeNotifierProvider(
      create: (_) => TripController(),
      child: const BusLinkApp(),
    ),
  );
}

class BusLinkApp extends StatelessWidget {
  const BusLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusLink',
      theme: AppTheme.lightTheme, // Using your clean theme
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
