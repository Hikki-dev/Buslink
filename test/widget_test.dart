import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for MethodChannel
import 'package:flutter_test/flutter_test.dart';
import 'package:buslink/main.dart';
import 'package:buslink/views/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; // Needed for Firebase.initializeApp
import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/services/auth_service.dart';
import 'package:buslink/utils/app_theme.dart';
import 'package:mockito/mockito.dart'; // Add 'mockito' to pubspec.yaml dev_dependencies if you haven't

// 1. Create a Mock User (Requires mockito)
// If you don't have mockito, you can try to skip the "Logged In" test for now.
class MockUser extends Mock implements User {}

// 2. Mock Auth Service
class MockAuthService extends AuthService {
  final Stream<User?> _userStream;

  MockAuthService({Stream<User?>? userStream})
      : _userStream = userStream ?? Stream.value(null);

  @override
  Stream<User?> get user => _userStream;
}

// 3. IMPORTANT: The Setup Function to stop Firebase Crashing
void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock the MethodChannel for Firebase Auth
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/firebase_auth');

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    channel,
    (MethodCall methodCall) async {
      return null; // Always return null to prevent crashes
    },
  );

  // Mock the MethodChannel for Firebase Core (App Initialization)
  const MethodChannel coreChannel =
      MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    coreChannel,
    (MethodCall methodCall) async {
      if (methodCall.method == 'Firebase#initializeCore') {
        return [
          {
            'name': '[DEFAULT]',
            'options': {
              'apiKey': '123',
              'appId': '123',
              'messagingSenderId': '123',
              'projectId': '123'
            },
            'pluginConstants': {},
          }
        ];
      }
      if (methodCall.method == 'Firebase#initializeApp') {
        return {
          'name': methodCall.arguments['appName'],
          'options': methodCall.arguments['options'],
          'pluginConstants': {},
        };
      }
      return null;
    },
  );
}

void main() {
  // 4. Run the setup before any tests
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('AuthWrapper Tests', () {
    // TEST CASE 1: User is NULL (Logged Out)
    testWidgets('Shows LoginScreen when user is null',
        (WidgetTester tester) async {
      // Inject the MockAuthService returning NULL
      final mockAuth = MockAuthService(userStream: Stream.value(null));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthService>.value(value: mockAuth),
            StreamProvider<User?>(
              create: (_) => mockAuth.user,
              initialData: null,
            ),
            ChangeNotifierProvider(create: (_) => TripController()),
            ChangeNotifierProvider(create: (_) => ThemeController()),
          ],
          child: Consumer<ThemeController>(
            builder: (context, themeController, child) {
              return MaterialApp(
                home: const AuthWrapper(),
              );
            },
          ),
        ),
      );

      // Allow animations to settle
      await tester.pumpAndSettle();

      // Expect LoginScreen to be present
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    // TEST CASE 2: User is LOGGED IN
    testWidgets('Shows Home/Main Screen when user is logged in',
        (WidgetTester tester) async {
      // Create a dummy user
      final mockUser = MockUser();

      // Inject the MockAuthService returning a USER
      final mockAuth = MockAuthService(userStream: Stream.value(mockUser));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthService>.value(value: mockAuth),
            StreamProvider<User?>(
              create: (_) => mockAuth.user,
              initialData:
                  mockUser, // Provide initial data so it doesn't flicker
            ),
            ChangeNotifierProvider(create: (_) => TripController()),
            ChangeNotifierProvider(create: (_) => ThemeController()),
          ],
          child: Consumer<ThemeController>(
            builder: (context, themeController, child) {
              return MaterialApp(
                home: const AuthWrapper(),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Expect LoginScreen to be GONE
      expect(find.byType(LoginScreen), findsNothing);

      // OPTIONAL: Expect your Home Screen to be present
      // expect(find.byType(MainScreen), findsOneWidget);
    });
  });
}
