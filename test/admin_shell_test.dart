import 'package:buslink/views/admin/layout/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_fonts.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(WidgetTester t, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: const Scaffold(
            body: AdminShell(selected: 3, child: Center(child: Text('page')))),
      ),
    ));
  }

  testWidgets('wide screens get the dark red side menu', (t) async {
    await pump(t, const Size(1440, 900));
    for (final label in [
      'Dashboard',
      'Trips',
      'Routes',
      'Bookings',
      'Refunds',
      'Feedback',
      'Analytics',
      'Users and roles',
      'Log out',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('phones show the page alone', (t) async {
    await pump(t, const Size(390, 844));
    expect(find.text('Users and roles'), findsNothing);
    expect(find.text('page'), findsOneWidget);
  });
}
