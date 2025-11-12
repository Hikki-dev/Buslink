import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'controllers/bus_controller.dart';
import 'views/home/home_screen.dart';
// import 'firebase_options.dart'; // TODO: Run 'flutterfire configure'

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  // try {
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // } catch (e) {
  //   print("Firebase not initialized (Using Mock Data): $e");
  // }

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => BusController())],
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins', // Ensure you add google_fonts or assets
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056D2), // Magiya Blue
          primary: const Color(0xFF0056D2),
          secondary: const Color(0xFFFFA726), // Action Orange
          surface: const Color(0xFFF4F7FC), // Light Grey Background
          error: const Color(0xFFD32F2F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0056D2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFA726), // Orange Buttons
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
