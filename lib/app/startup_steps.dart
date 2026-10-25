import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../firebase_options.dart';
import '../services/cache_service.dart';
import 'startup.dart';

/// The things BusLink needs before it can show its first real screen.
///
/// They all start at once. Only Firebase can stop the app from starting:
/// without it there is no sign-in and no data. Everything else is nice to have,
/// so if it fails the app still opens.
///
/// Slower, less important work (push notifications, Stripe, Google sign-in)
/// is not here at all. It starts after the first screen is up, in
/// `BackgroundServices.start`.
AppStartup standardStartup() => AppStartup([
      // Settings saved on this device (language, theme).
      StartupStep('cache', () => CacheService().init(), critical: false),

      // Date names for English, Sinhala and Tamil.
      StartupStep('dates', initializeDateFormatting, critical: false),

      // The .env file (the Stripe key). The app opens without it.
      StartupStep('env', () => dotenv.load(fileName: '.env'), critical: false),

      // Firebase itself. Starting it twice throws, so a retry skips it.
      StartupStep('firebase', _startFirebase),

      // Who is signed in. Waiting for this once means the first screen is the
      // right one, instead of the sign-in page flashing up for people who are
      // already signed in.
      StartupStep(
        'auth',
        () => FirebaseAuth.instance
            .authStateChanges()
            .first
            .timeout(const Duration(seconds: 4), onTimeout: () => null),
        critical: false,
        after: const ['firebase'],
      ),
    ]);

Future<void> _startFirebase() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
  }
  // Local testing only: flutter build web --dart-define=USE_EMULATOR=true
  if (const bool.fromEnvironment('USE_EMULATOR')) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  try {
    // On a phone, keep data on the device so the app works with a poor
    // connection. In a browser the cache lives in IndexedDB, which is slow to
    // open in Safari and makes the app start late and stutter, so it is off.
    FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: !kIsWeb,
        cacheSizeBytes: kIsWeb ? null : Settings.CACHE_SIZE_UNLIMITED);
  } catch (e) {
    // Settings can only be set once, before Firestore is first used.
    debugPrint('Firestore settings were already applied: $e');
  }
}
