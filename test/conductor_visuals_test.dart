import 'package:buslink/models/trip_model.dart';
import 'package:buslink/utils/app_theme.dart';
import 'package:buslink/views/conductor/conductor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/app_fonts.dart';

Ticket _ticket({String? shortId = '4821'}) => Ticket(
      ticketId: 'abc123',
      tripId: 'trip1',
      userId: 'u',
      seatNumbers: const [9, 10],
      passengerName: 'Nimal Perera',
      passengerPhone: '077',
      bookingTime: DateTime(2026, 11, 6),
      totalAmount: 2400,
      shortId: shortId,
      tripData: {
        'fromCity': 'Colombo',
        'toCity': 'Kandy',
        'busNumber': 'NP-1234',
        'departureDateTime': Timestamp.fromDate(DateTime(2026, 11, 7, 6, 30)),
        'arrivalDateTime': Timestamp.fromDate(DateTime(2026, 11, 7, 9, 45)),
        'price': 1200,
        'status': 'scheduled',
      },
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(900, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
        body: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child))),
  ));
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  group('ticket verified', () {
    testWidgets('shows who, which seats, and the code to compare',
        (tester) async {
      final t = _ticket();
      await _pump(
          tester,
          TicketVerifiedCard(
            ticket: t,
            onApprove: () {},
            seatStream: Stream.value(Trip.fromMap(t.tripData, t.tripId)),
          ));
      expect(find.text('Ticket is valid'), findsOneWidget);
      expect(find.text('Nimal Perera'), findsOneWidget);
      expect(find.text('Seat 9'), findsOneWidget);
      expect(find.text('Seat 10'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.textContaining('must match'), findsOneWidget);
      expect(find.bySemanticsLabel('Verified code 4821'), findsOneWidget);
      expect(find.text('Approve Boarding'), findsOneWidget);
    });

    testWidgets('a missing code says N/A instead of crashing', (tester) async {
      final t = _ticket(shortId: null);
      await _pump(
          tester,
          TicketVerifiedCard(
            ticket: t,
            onApprove: () {},
            seatStream: Stream.value(Trip.fromMap(t.tripData, t.tripId)),
          ));
      expect(find.text('N/A'), findsOneWidget);
    });

    testWidgets('Approve Boarding calls back', (tester) async {
      final t = _ticket();
      var approved = false;
      await _pump(
          tester,
          TicketVerifiedCard(
            ticket: t,
            onApprove: () => approved = true,
            seatStream: Stream.value(Trip.fromMap(t.tripData, t.tripId)),
          ));
      await tester.ensureVisible(find.text('Approve Boarding'));
      await tester.tap(find.text('Approve Boarding'));
      expect(approved, isTrue);
    });
  });

  testWidgets('rejected ticket explains why and offers Try again',
      (tester) async {
    var closed = false;
    await _pump(
        tester,
        TicketRejectedCard(
          title: 'Ticket not accepted',
          message: 'Access Denied: Trip expired >12h ago',
          onClose: () => closed = true,
        ));
    expect(find.text('Ticket not accepted'), findsOneWidget);
    expect(find.text('Access Denied: Trip expired >12h ago'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(closed, isTrue);
  });
}
