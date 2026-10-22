import 'package:buslink/models/boarding_result.dart';
import 'package:buslink/models/trip_model.dart';
import 'package:buslink/utils/app_theme.dart';
import 'package:buslink/views/conductor/conductor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_fonts.dart';

Ticket _ticket({Map<String, dynamic> extra = const {}}) => Ticket.fromMap({
      'tripId': 't1',
      'userId': 'u',
      'seatNumbers': [9, 10],
      'passengerName': 'Nimal',
      'passengerPhone': '077',
      'bookingTime': Timestamp.fromDate(DateTime(2026, 11, 6)),
      'totalAmount': 2400,
      'tripData': {'fromCity': 'Colombo', 'toCity': 'Kandy'},
      'status': 'confirmed',
      ...extra,
    }, 'abc');

void main() {
  group('decideBoarding', () {
    test('a fresh confirmed ticket can board', () {
      expect(decideBoarding({'status': 'confirmed'}).status,
          BoardingStatus.recorded);
    });

    test('a missing ticket is not found', () {
      expect(decideBoarding(null).status, BoardingStatus.notFound);
    });

    test('a ticket that was already boarded is rejected with the time', () {
      final at = DateTime(2026, 11, 7, 6, 31);
      final r = decideBoarding(
          {'status': 'confirmed', 'boardedAt': Timestamp.fromDate(at)});
      expect(r.status, BoardingStatus.alreadyBoarded);
      expect(r.boardedAt, at);
    });

    test('a cancelled ticket cannot board, even if it has a boardedAt', () {
      expect(
          decideBoarding({
            'status': 'cancelled',
            'boardedAt': Timestamp.fromDate(DateTime(2026, 11, 7)),
          }).status,
          BoardingStatus.cancelled);
    });

    test('a boardedAt that is not yet resolved (null) counts as not boarded',
        () {
      expect(decideBoarding({'status': 'confirmed', 'boardedAt': null}).status,
          BoardingStatus.recorded);
    });
  });

  group('Ticket', () {
    test('is not boarded by default', () {
      final t = _ticket();
      expect(t.isBoarded, isFalse);
      expect(t.boardedBy, isNull);
    });

    test('reads boardedAt / boardedBy', () {
      final at = DateTime(2026, 11, 7, 6, 31);
      final t = _ticket(extra: {
        'boardedAt': Timestamp.fromDate(at),
        'boardedBy': 'cond1',
      });
      expect(t.isBoarded, isTrue);
      expect(t.boardedAt, at);
      expect(t.boardedBy, 'cond1');
    });
  });

  test('already-boarded message names the time and the rule', () {
    final m = alreadyBoardedMessage(DateTime(2026, 11, 7, 18, 5));
    expect(m, contains('6:05 PM'));
    expect(m, contains('only once'));
  });

  group('Approve Boarding button', () {
    setUpAll(loadAppFonts);

    Future<void> pump(WidgetTester tester, Widget card) async {
      tester.view.physicalSize = const Size(900, 2600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: SingleChildScrollView(child: card)),
      ));
    }

    testWidgets('calls onApprove when tapped', (tester) async {
      var taps = 0;
      await pump(
          tester,
          TicketVerifiedCard(
              ticket: _ticket(),
              seatStream: const Stream.empty(),
              onApprove: () => taps++));
      await tester.tap(find.text('Approve Boarding'));
      expect(taps, 1);
    });

    testWidgets('is disabled and shows a spinner while saving', (tester) async {
      var taps = 0;
      await pump(
          tester,
          TicketVerifiedCard(
              ticket: _ticket(),
              seatStream: const Stream.empty(),
              busy: true,
              onApprove: () => taps++));
      expect(find.text('Approve Boarding'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      expect(taps, 0);
    });
  });
}
