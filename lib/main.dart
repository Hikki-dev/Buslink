// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'controllers/trip_controller.dart';
import 'utils/app_theme.dart';
import 'views/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // FIX: Replaced print with debugPrint, which is safer
    debugPrint("Failed to initialize Firebase: $e");
  }

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, // <-- This will now work
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
