import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:buslink/main.dart' as app;

import 'package:intl/date_symbol_data_local.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full System Test: Admin -> Conductor -> User',
      (WidgetTester tester) async {
    print('🚀 TEST STARTING');
    await initializeDateFormatting();
    await tester.pumpWidget(const app.AppBootstrapper());
    print('🚀 APP STARTED (Pumped)');
    await tester.pumpAndSettle();

    // --- 0. CHECK & CLEAR EXISTING SESSION ---
    print('🚀 [0/3] Checking for existing session...');

    // Check for Admin Dashboard
    if (find.text('Trip Management').evaluate().isNotEmpty) {
      print('⚠️ Found existing Admin session. Logging out...');
      final adminProfileKey = find.byKey(const Key('admin_profile_menu'));
      // Try tapping key or icon
      if (adminProfileKey.evaluate().isNotEmpty) {
        await tester.tap(adminProfileKey, warnIfMissed: false);
      } else {
        await tester.tap(find.byIcon(Icons.person), warnIfMissed: false);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    // Check for Conductor Dashboard
    else if (find.text('Scanning').evaluate().isNotEmpty ||
        find.byKey(const Key('conductor_logout_btn')).evaluate().isNotEmpty) {
      print('⚠️ Found existing Conductor session. Logging out...');
      // Try button first
      final btn = find.byKey(const Key('conductor_logout_btn'));
      if (btn.evaluate().isNotEmpty) {
        await tester.tap(btn);
      } else {
        // Maybe text "Logout"?
        if (find.text("Logout").evaluate().isNotEmpty) {
          await tester.tap(find.text("Logout"));
        } else {
          // Try icon
          await tester.tap(find.byIcon(Icons.logout));
        }
      }
      await tester.pumpAndSettle();
    }
    // Check for Customer Dashboard
    else if (find.textContaining('Find your journey').evaluate().isNotEmpty) {
      print('⚠️ Found existing User session. Logging out...');
      // Navigate to Profile
      await tester.tap(find.byIcon(Icons.person_outline), warnIfMissed: false);
      await tester.pumpAndSettle();
      // Scroll and Logout
      await tester.scrollUntilVisible(
        find.text('Log Out'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Log Out'), warnIfMissed: false);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // Double check we are on Login Screen (or Guest Home which redirects to Login for booking... wait, bootstrapper forces Login for Guests if not in AuthWrapper guest handling?)
    // AuthWrapper: "3. Guest / Default -> Force Login"
    // So we should be at LoginScreen now.

    // Safety Pump
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // --- 1. ADMIN LOGIN ---
    print('🚀 [1/3] Starting Admin Login...');

    // Ensure we are on Login Screen
    expect(find.byType(TextField), findsAtLeastNWidgets(1),
        reason: "Login fields missing");

    await tester.enterText(find.byType(TextField).at(0), 'admin@buslink.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify Admin Dashboard
    expect(find.text('Trip Management'), findsOneWidget);
    print('✅ Admin Login Verified');

    // Admin Logout
    print('🚀 [1/3] Logging out Admin...');
    // Use the Key we added
    final adminProfileKey = find.byKey(const Key('admin_profile_menu'));
    if (adminProfileKey.evaluate().isNotEmpty) {
      await tester.tap(adminProfileKey, warnIfMissed: false);
    } else {
      // Fallback to finding by icon if key fails (e.g. wrapper issue)
      await tester.tap(find.byIcon(Icons.person), warnIfMissed: false);
    }
    await tester.pumpAndSettle();

    // Tap Logout from Menu
    await tester.tap(find.text('Logout'), warnIfMissed: false);
    await tester.pumpAndSettle();
    print('✅ Admin Logout Complete');

    // --- 2. CONDUCTOR LOGIN ---
    print('🚀 [2/3] Starting Conductor Login...');

    await tester.enterText(
        find.byType(TextField).at(0), 'conductor@buslink.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify Conductor Dashboard
    expect(find.text('My Trips'), findsOneWidget);
    print('✅ Conductor Login Verified');

    // Conductor Logout
    print('🚀 [2/3] Logging out Conductor...');
    await tester.tap(find.byKey(const Key('conductor_logout_btn')),
        warnIfMissed: false);
    await tester.pumpAndSettle();
    print('✅ Conductor Logout Complete');

    // --- 3. USER LOGIN ---
    print('🚀 [3/3] Starting User Login...');

    await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify User Dashboard (Home Screen)
    // "Find your journey" or similar text
    expect(find.textContaining('Find your journey'), findsOneWidget);
    print('✅ User Login Verified');

    // User Logout
    print('🚀 [3/3] Logging out User...');

    // 1. Go to Profile Tab
    // Note: BottomNavigationBarItem does not always expose Key easily to finder.
    // Instead, tap the icon inside it.
    await tester.tap(find.byIcon(Icons.person_outline), warnIfMissed: false);
    await tester.pumpAndSettle();

    // 2. Tap Logout Tile
    // Finding by text "Log Out" (red text)
    // We can use scrolling if needed, but standard screen size usually fits
    await tester.scrollUntilVisible(
      find.text('Log Out'),
      500.0,
      scrollable: find.byType(Scrollable).last, // Scroll the profile list
    );
    await tester.tap(find.text('Log Out'), warnIfMissed: false);

    // 3. Confirm Dialog might appear? Or specific logic in ProfileScreen.
    // ProfileScreen logic: showDialog -> CircularProgress -> SignOut -> Nav.
    // So no confirmation 'YES' button needed, just wait.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    print('✅ User Logout Complete');

    print('🎉 ALL TESTS PASSED!');
  });
}
