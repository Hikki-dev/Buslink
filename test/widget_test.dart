// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buslink/main.dart'; // Import your main.dart
import 'package:buslink/views/auth/login_screen.dart'; // Import the login screen
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/services/auth_service.dart';
import 'package:buslink/utils/app_theme.dart';

// A mock auth service for testing
class MockAuthService extends AuthService {
  // --- FIX: This getter now correctly overrides the one in AuthService ---
  @override
  Stream<User?> get user => Stream.value(null); // Simulate user is logged out
}

void main() {
  testWidgets('AuthWrapper shows LoginScreen when user is null',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthService>(create: (_) => MockAuthService()),
          StreamProvider<User?>(
            // --- FIX: This 'user' getter now exists ---
            create: (context) => context.read<AuthService>().user,
            initialData: null,
          ),
          ChangeNotifierProvider(create: (_) => TripController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: Consumer<ThemeController>(
          builder: (context, themeController, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeController.themeMode,
              home: const AuthWrapper(),
            );
          },
        ),
      ),
    );

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
}
