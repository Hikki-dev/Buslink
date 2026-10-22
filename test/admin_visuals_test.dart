import 'package:buslink/utils/app_theme.dart';
import 'package:buslink/views/admin/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_fonts.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: child)));

void main() {
  setUpAll(loadAppFonts);

  group('statusStyle', () {
    test('every known status has a word and an icon, not just a colour', () {
      for (final s in [
        'confirmed',
        'boarded',
        'cancelled',
        'completed',
        'refund_requested',
        'refunded',
        'pending',
        'approved',
        'rejected',
        'processed',
        'failed',
        'delayed',
        'scheduled',
        'boarding',
        'departed',
      ]) {
        final st = statusStyle(s);
        expect(st.label, isNotEmpty, reason: s);
        expect(st.icon, isNot(Icons.help_outline), reason: s);
      }
    });

    test('is case- and space-insensitive', () {
      expect(statusStyle('Refund Requested').label, 'Refund requested');
      expect(statusStyle('CONFIRMED').label, 'Confirmed');
    });

    test('unknown or missing status degrades gracefully', () {
      expect(statusStyle(null).label, 'Unknown');
      expect(statusStyle('weird_thing').label, 'Weird thing');
    });
  });

  testWidgets('StatusChip shows icon + word and a screen-reader label',
      (tester) async {
    await _pump(tester, const StatusChip('cancelled'));
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.bySemanticsLabel('Status: Cancelled'), findsOneWidget);
  });

  testWidgets('TripFormSteps marks done steps and names the current one',
      (tester) async {
    await _pump(tester, const TripFormSteps(current: 1));
    expect(find.byIcon(Icons.check), findsOneWidget); // step 1 done
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Route'), findsNothing); // only current label shown
    expect(find.bySemanticsLabel('Step 2 of 3: Schedule'), findsOneWidget);
  });
}
