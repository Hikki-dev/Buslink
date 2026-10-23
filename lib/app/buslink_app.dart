import 'package:buslink/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../controllers/trip_controller.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../utils/app_theme.dart';
import '../views/admin/admin_dashboard.dart';
import '../views/auth/login_screen.dart';
import '../views/booking/payment_success_screen.dart';
import 'auth_gate.dart';

/// Lets code without a BuildContext (for example a push notification) reach
/// the app's navigator.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// The real app: its services, its theme, its languages and its routes.
/// It is only built once start-up has finished, so everything it needs
/// (Firebase, [authService]) is ready.
class BusLinkApp extends StatelessWidget {
  const BusLinkApp({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: authService),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        // Start-up already waited for Firebase to say who is signed in, so
        // this is right from the very first frame.
        StreamProvider<User?>(
          create: (_) => authService.user,
          initialData: authService.currentUser,
        ),
        ChangeNotifierProvider(create: (_) => TripController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeController, LanguageProvider>(
        builder: (context, themeController, languageProvider, _) {
          return MaterialApp(
            navigatorKey: appNavigatorKey,
            title: 'BusLink',
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('si'), Locale('ta')],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/admin-dashboard': (context) => const AdminDashboard(),
            },
            onGenerateRoute: (settings) {
              if (settings.name?.startsWith('/payment_success') ?? false) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const PaymentSuccessScreen(),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}
