import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:buslink/main.dart' as app;

import 'package:intl/date_symbol_data_local.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Full System Test: Admin -> Conductor -> User',
      (WidgetTester tester) async {
    // Helper for safe pumping
    Future<void> pumpAndSettleSafe(Duration? duration) async {
      try {
        await tester.pumpAndSettle(duration ?? const Duration(seconds: 2));
      } catch (e) {
        print('⚠️ pumpAndSettle timed out (safe warning), continuing...');
        // Force a single pump to clear any pending microtasks if possible
        await tester.pump();
      }
    }

    print('🚀 TEST STARTING');
    await initializeDateFormatting();
    await tester.pumpWidget(const app.AppBootstrapper());
    print('🚀 APP STARTED (Pumped)');
    await pumpAndSettleSafe(null);

    // --- 0. CHECK & CLEAR EXISTING SESSION ---
    print('🚀 [0/3] Checking for existing session...');

    // Allow substantial time for AppBootstrapper and Firebase Init
    await pumpAndSettleSafe(const Duration(seconds: 5));

    // --- HANDLE PERMISSION DIALOG (Web/Mobile) ---
    if (find.byKey(const Key('permission_later_btn')).evaluate().isNotEmpty) {
      print('⚠️ Found Permission Dialog. Dismissing...');
      await tester.tap(find.byKey(const Key('permission_later_btn')));
      await pumpAndSettleSafe(null);
    }

    // If we are NOT on the Login Screen, we must logout
    if (find.byKey(const Key('login_email_field')).evaluate().isEmpty) {
      print(
          '⚠️ Not on Login Screen. Attempting to determine session and logout...');

      // 1. Try ADMIN Logout
      // Check for Admin specific widget (Trip Management) OR Admin Profile Key
      if (find.text('Trip Management').evaluate().isNotEmpty ||
          find.byKey(const Key('admin_profile_menu')).evaluate().isNotEmpty) {
        print('   -> Detected Admin Session');
        final adminProfileKey = find.byKey(const Key('admin_profile_menu'));
        if (adminProfileKey.evaluate().isNotEmpty) {
          await tester.tap(adminProfileKey);
        } else {
          // Fallback
          await tester.tap(find.byIcon(Icons.person));
        }
        await pumpAndSettleSafe(null);
        await tester.tap(find.text('Logout'));
        await pumpAndSettleSafe(null);
      }

      // 2. Try CONDUCTOR Logout
      else if (find
              .byKey(const Key('conductor_logout_btn'))
              .evaluate()
              .isNotEmpty ||
          find.text('Scanning').evaluate().isNotEmpty) {
        print('   -> Detected Conductor Session');
        // Might be on dashboard or scanning
        if (find
            .byKey(const Key('conductor_logout_btn'))
            .evaluate()
            .isNotEmpty) {
          await tester
              .ensureVisible(find.byKey(const Key('conductor_logout_btn')));
          await tester.tap(find.byKey(const Key('conductor_logout_btn')));
        } else {
          // Maybe navigate back or look for logout icon?
          // Assuming dashboard is main view
        }
        await pumpAndSettleSafe(null);
      }

      // 3. Try USER Logout (Default Fallback)
      else {
        print('   -> Detected User (or Unknown) Session');
        // Assuming we are on Home or similar. Need to go to Profile.
        // User Navbar has Icons.person_outline
        final profileIcon = find.byIcon(Icons.person_outline);
        if (profileIcon.evaluate().isNotEmpty) {
          await tester.tap(profileIcon);
          await pumpAndSettleSafe(null);

          // Now on Profile Screen. Look for Log Out.
          final logoutBtn = find.text('Log Out');
          if (logoutBtn.evaluate().isNotEmpty) {
            await tester.scrollUntilVisible(
              logoutBtn,
              500.0,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.tap(logoutBtn);
            await pumpAndSettleSafe(const Duration(seconds: 2));
          } else {
            print(
                "❌ Could not find Log Out button on presumed Profile screen.");
          }
        } else {
          print("❌ Could not find Profile Icon to logout.");
        }
      }

      // Final Setup Check
      await pumpAndSettleSafe(const Duration(seconds: 5));
    } else {
      print('✅ Already on Login Screen');
    }

    // Safety Pump
    await pumpAndSettleSafe(const Duration(seconds: 2));

    // --- 1. ADMIN LOGIN ---
    print('🚀 [1/3] Starting Admin Login...');

    // Ensure we are on Login Screen
    expect(find.byKey(const Key('login_email_field')), findsOneWidget,
        reason: "Login Email field missing");

    await tester.enterText(
        find.byKey(const Key('login_email_field')), 'admin@buslink.com');
    await tester.enterText(
        find.byKey(const Key('login_password_field')), '123456');
    await tester.tap(find.byKey(const Key('login_button')));
    await pumpAndSettleSafe(const Duration(seconds: 4));

    // Verify Admin Dashboard
    // Verify Admin Dashboard (Desktop says "Management", Mobile says "Trip Management")
    expect(find.textContaining('Management'), findsOneWidget);
    expect(find.textContaining('Management'), findsOneWidget);
    print('✅ Admin Login Verified');
    await binding.takeScreenshot('admin_dashboard');

    // --- HANDLE PERMISSION DIALOG (After Login) ---
    // Loop to ensure all dialogs are dismissed
    int adminDialogAttempts = 0;
    while (
        find.byKey(const Key('permission_later_btn')).evaluate().isNotEmpty &&
            adminDialogAttempts < 5) {
      print(
          '⚠️ Found Permission Dialog (Admin - Attempt ${adminDialogAttempts + 1}). Dismissing...');
      await tester.tap(find.byKey(const Key('permission_later_btn')).last,
          warnIfMissed: false);
      await pumpAndSettleSafe(const Duration(seconds: 2));
      adminDialogAttempts++;
    }

    // Admin Logout
    print('🚀 [1/3] Logging out Admin...');
    await tester.tap(find.byKey(const Key('admin_profile_menu')));
    await pumpAndSettleSafe(null);
    await tester.tap(find.text('Logout'));
    await pumpAndSettleSafe(null);
    print('✅ Admin Logout Complete');

    // --- 2. CONDUCTOR LOGIN ---
    print('🚀 [2/3] Starting Conductor Login...');

    await tester.enterText(
        find.byKey(const Key('login_email_field')), 'conductor@buslink.com');
    await tester.enterText(
        find.byKey(const Key('login_password_field')), '123456');
    await tester.ensureVisible(find.byKey(const Key('login_button')));
    await tester.tap(find.byKey(const Key('login_button')));
    await pumpAndSettleSafe(const Duration(seconds: 4));

    // Verify Conductor Dashboard
    expect(find.text('Conductor Dashboard'), findsOneWidget);
    expect(find.text('Conductor Dashboard'), findsOneWidget);
    print('✅ Conductor Login Verified');
    await binding.takeScreenshot('conductor_dashboard');

    // --- HANDLE PERMISSION DIALOG (Conductor) ---
    // Loop to ensure all dialogs are dismissed
    // Loop to ensure all dialogs are dismissed (Conductor)
    // Loop to ensure all dialogs are dismissed (Conductor)
    int conductorDialogAttempts = 0;
    while (
        (find.byKey(const Key('permission_later_btn')).evaluate().isNotEmpty ||
                find.text('Decline').evaluate().isNotEmpty) &&
            conductorDialogAttempts < 5) {
      // 1. Handle Location Dialog (Decline)
      if (find.text('Decline').evaluate().isNotEmpty) {
        print('⚠️ Found Location Dialog (Conductor). Dismissing...');
        await tester.tap(find.text('Decline').last);
        await pumpAndSettleSafe(const Duration(seconds: 1));
      }

      // 2. Handle Notification Dialog (Later)
      if (find.byKey(const Key('permission_later_btn')).evaluate().isNotEmpty) {
        final int count =
            find.byKey(const Key('permission_later_btn')).evaluate().length;
        print(
            '⚠️ Found Notification Dialog (Conductor). Count: $count. Dismissing...');
        final target = find.byKey(const Key('permission_later_btn')).last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await pumpAndSettleSafe(const Duration(seconds: 1));
      }
      conductorDialogAttempts++;
    }

    // Conductor Logout
    print('🚀 [2/3] Logging out Conductor...');
    await tester.ensureVisible(find.byKey(const Key('conductor_logout_btn')));
    await tester.tap(find.byKey(const Key('conductor_logout_btn')));
    await pumpAndSettleSafe(null);
    print('✅ Conductor Logout Complete');

    // --- 3. USER LOGIN ---
    print('🚀 [3/3] Starting User Login...');

    // Wait for Logout to complete and Login screen to appear
    await pumpAndSettleSafe(const Duration(seconds: 4));

    // Check if we are actually on the login screen
    if (find.byKey(const Key('login_email_field')).evaluate().isEmpty) {
      print(
          "⚠️ Login Screen NOT FOUND after Conductor Logout. Dumping widget tree...");
      // In a real scenario we might dump the tree, but here we just wait longer or fail gracefully
      await pumpAndSettleSafe(const Duration(seconds: 5));
    }

    await tester.ensureVisible(find.byKey(const Key('login_email_field')));
    await tester.enterText(
        find.byKey(const Key('login_email_field')), 'test@test.com');
    await tester.enterText(
        find.byKey(const Key('login_password_field')), '123456');
    await tester.ensureVisible(find.byKey(const Key('login_button')));
    await tester.tap(find.byKey(const Key('login_button')));
    await pumpAndSettleSafe(const Duration(seconds: 4));

    // Verify User Dashboard (Home Screen)
    expect(find.text('BusLink'), findsAtLeastNWidgets(1));
    print('✅ User Login Verified');
    await binding.takeScreenshot('user_dashboard');

    // --- HANDLE PERMISSION DIALOG (User) ---
    // Loop to ensure all dialogs are dismissed
    // Loop to ensure all dialogs are dismissed (User)
    int userDialogAttempts = 0;
    while (
        find.byKey(const Key('permission_later_btn')).evaluate().isNotEmpty &&
            userDialogAttempts < 5) {
      print(
          '⚠️ Found Permission Dialog (User - Attempt ${userDialogAttempts + 1}). Dismissing...');
      await tester.tap(find.byKey(const Key('permission_later_btn')),
          warnIfMissed: false);
      await pumpAndSettleSafe(const Duration(seconds: 2));
      userDialogAttempts++;
    }

    // User Logout
    print('🚀 [3/3] Logging out User...');
    await tester.tap(find.byIcon(Icons.person_outline));
    await pumpAndSettleSafe(null);

    await tester.scrollUntilVisible(
      find.text('Log Out'),
      500.0,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Log Out'));
    await pumpAndSettleSafe(const Duration(seconds: 2));

    print('✅ User Logout Complete');

    // Final Screenshot
    await binding.takeScreenshot('final_state');

    print('🎉 ALL TESTS PASSED!');
  });
}
