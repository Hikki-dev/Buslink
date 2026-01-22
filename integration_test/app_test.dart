import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:integration_test/integration_test.dart';
import 'package:buslink/main.dart' as app;

void main() {
  patrolTest(
    'Admin and Conductor Login Flow',
    (PatrolIntegrationTester $) async {
      // 1. Start App
      app.main();
      await $.pumpAndSettle();

      // --- ADMIN LOGIN ---
      print('🚀 Starting Admin Login Test...');

      // If already logged in, logout (Optional safeguard)
      if ($(Icons.logout).exists) {
        await $(Icons.logout).tap();
        await $.pumpAndSettle();
      }

      // Check current state (expect Login Screen)
      if (!$(Icons.email).exists) {
        // Might be in splash or dashboard if cached.
        // Assuming fresh install or logged out state for test simplicity.
        // If dashboard, log out.
        if ($(Icons.dashboard).exists || $(Icons.directions_bus).exists) {
          // Try getting to logout
          // Verify if we have a logout button visible
          await $(Icons.logout).scrollTo().tap();
          await $.pumpAndSettle();
        }
      }

      // Fill Email
      await $(TextField).at(0).enterText('admin@buslink.com');
      // Fill Password
      await $(TextField).at(1).enterText('123456');

      // Tap Login
      // Look for "Login" text or button
      await $('Login').tap();

      // Wait for Dashboard
      await $.pumpAndSettle(duration: Duration(seconds: 4));

      // Verify Admin Dashboard
      // Check for Admin specific text
      expect($('Admin Dashboard'), findsOneWidget);
      // Or "Net Revenue"
      expect($('Net Revenue'), findsAtLeastNWidgets(1));

      print('✅ Admin Login Successful');

      // --- LOGOUT ---
      await $(Icons.logout).tap();
      await $.pumpAndSettle();

      // --- CONDUCTOR LOGIN ---
      print('🚀 Starting Conductor Login Test...');

      await $(TextField).at(0).enterText('conductor@buslink.com');
      await $(TextField).at(1).enterText('123456');
      await $('Login').tap();

      await $.pumpAndSettle(duration: Duration(seconds: 4));

      // Verify Conductor Dashboard
      expect($('My Trips'),
          findsOneWidget); // Assuming Conductor dashboard has "My Trips" or similar
      // Or check for "Scan Ticket" FAB if it exists
      // expect($(Icons.qr_code_scanner), findsOneWidget);

      print('✅ Conductor Login Successful');
    },
  );
}
