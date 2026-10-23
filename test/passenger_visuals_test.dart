import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/l10n/app_localizations.dart';
import 'package:buslink/models/route_model.dart';
import 'package:buslink/models/schedule_model.dart';
import 'package:buslink/models/trip_model.dart';
import 'package:buslink/models/trip_view_model.dart';
import 'package:buslink/services/firestore_service.dart';
import 'package:buslink/utils/app_theme.dart';
import 'package:buslink/views/booking/bus_layout_widget.dart';
import 'package:buslink/views/booking/my_trips_screen.dart';
import 'package:buslink/views/results/bus_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/app_fonts.dart';

class _FakeController extends TripController {
  @override
  Future<bool> isRouteFavorite(String from, String to) async => false;
}

class _FakeService extends FirestoreService {
  final Trip trip;
  _FakeService(this.trip);
  @override
  Stream<Trip> getTripStream(String tripId) => Stream.value(trip);
}

EnrichedTrip _trip(
    {String status = 'Scheduled', int delay = 0, int booked = 12}) {
  final t = Trip(
    id: 't',
    scheduleId: 's',
    date: DateTime(2026, 11, 7),
    originCity: 'Colombo',
    destinationCity: 'Nuwara Eliya',
    departureDateTime: DateTime(2026, 11, 7, 6, 30),
    arrivalDateTime: DateTime(2026, 11, 7, 11, 45),
    price: 1200,
    status: status,
    delayMinutes: delay,
    totalSeats: 40,
    bookedSeatNumbers: List.generate(booked, (i) => '${i + 1}'),
  );
  return EnrichedTrip(
    trip: t,
    schedule: ScheduleModel(
        id: 's',
        routeId: 'r',
        busNumber: 'NP-1234',
        operatorName: 'SuperLine Express',
        busType: 'Luxury AC',
        amenities: const [],
        recurrenceDays: const [1],
        departureTime: '06:30',
        basePrice: 1200,
        totalSeats: 40),
    route: RouteModel(
        id: 'r',
        originCity: 'Colombo',
        destinationCity: 'Nuwara Eliya',
        via: 'Kandy',
        stops: const [],
        distanceKm: 160,
        estimatedDurationMins: 315,
        isActive: true),
  );
}

Future<void> _pumpCard(WidgetTester tester, EnrichedTrip e) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: ChangeNotifierProvider<TripController>(
        create: (_) => _FakeController(),
        child: Provider<FirestoreService>.value(
          value: _FakeService(e.trip),
          child: SingleChildScrollView(child: BusTicketCard(trip: e)),
        ),
      ),
    ),
  ));
  await tester.pump();
}

Ticket _ticket(String status, Duration departIn) => Ticket(
      ticketId: 'T',
      tripId: 'trip',
      userId: 'u',
      seatNumbers: const [9, 10],
      passengerName: 'Nimal',
      passengerPhone: '077',
      bookingTime: DateTime.now(),
      totalAmount: 2400,
      tripData: {
        'fromCity': 'Colombo',
        'toCity': 'Kandy',
        'status': status,
        'departureDateTime': Timestamp.fromDate(DateTime.now().add(departIn)),
      },
    );

Future<void> _pumpPass(WidgetTester tester, Ticket t) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        body: SingleChildScrollView(
            child: BoardingPassCard(ticket: t, shouldListen: false))),
  ));
  await tester.pump();
}

void main() {
  setUpAll(loadAppFonts);

  test('busDuration and seatsLevel are plain', () {
    expect(busDuration(const Duration(hours: 5, minutes: 15)), '5h 15m');
    expect(busDuration(const Duration(hours: 3)), '3h');
    expect(busDuration(const Duration(minutes: 40)), '40m');
    expect(busDuration(const Duration(minutes: -5)), '0m');
    expect(seatsLevel(28), SeatsLevel.plenty);
    expect(seatsLevel(5), SeatsLevel.few);
    expect(seatsLevel(0), SeatsLevel.none);
  });

  group('bus card', () {
    testWidgets(
        'normal bus: real city names, bus type, 12-hour times, no fake badge',
        (tester) async {
      await _pumpCard(tester, _trip());
      expect(find.text('nuwara_eliya'), findsNothing);
      expect(find.text('Highly Rated'), findsNothing);
      expect(find.text('Luxury AC · NP-1234'), findsOneWidget);
      expect(find.text('06:30 AM'), findsOneWidget);
      expect(find.text('5h 15m'), findsOneWidget);
      expect(find.text('28 seats left'), findsOneWidget);
      expect(find.text('Book Now'), findsOneWidget);
    });

    testWidgets('long city names fit a 390px phone without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(780, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final e = _trip();
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ChangeNotifierProvider<TripController>(
            create: (_) => _FakeController(),
            child: Provider<FirestoreService>.value(
              value: _FakeService(e.trip),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(child: BusTicketCard(trip: e)),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull); // no RenderFlex overflow
      expect(find.text('via Kandy'), findsOneWidget);
    });

    testWidgets('delayed and nearly full say so in words', (tester) async {
      await _pumpCard(tester, _trip(status: 'delayed', delay: 30, booked: 36));
      expect(find.text('Running 30 minutes late'), findsOneWidget);
      expect(find.text('Only 4 seats left'), findsOneWidget);
    });

    testWidgets('cancelled and full buses cannot be selected', (tester) async {
      await _pumpCard(tester, _trip(status: 'cancelled'));
      expect(find.textContaining('This trip is cancelled'), findsOneWidget);
      expect(find.text('Book Now'), findsNothing);
      await _pumpCard(tester, _trip(booked: 40));
      expect(find.textContaining('This bus is full'), findsOneWidget);
      expect(find.text('Book Now'), findsNothing);
    });
  });

  group('my trips card', () {
    testWidgets('upcoming soon: track button and quiet refund', (tester) async {
      await _pumpPass(tester, _ticket('scheduled', const Duration(hours: 2)));
      expect(find.text('TRACK NOW'), findsOneWidget);
      expect(find.text('Refund'), findsOneWidget);
    });

    testWidgets('days away: no track button', (tester) async {
      await _pumpPass(tester, _ticket('scheduled', const Duration(days: 4)));
      expect(find.text('TRACK NOW'), findsNothing);
      expect(find.text('Refund'), findsOneWidget);
    });

    testWidgets('cancelled: neither track nor refund', (tester) async {
      await _pumpPass(tester, _ticket('cancelled', const Duration(days: 3)));
      expect(find.text('TRACK NOW'), findsNothing);
      expect(find.text('Refund'), findsNothing);
    });
  });

  testWidgets('seat map: every seat has a spoken label, selected shows a tick',
      (tester) async {
    final t = _trip(booked: 0).trip.copyWith(bookedSeatNumbers: const ['2']);
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    int? tapped;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: BusLayoutWidget(
              trip: t,
              totalSeats: 40,
              isDark: false,
              selectedSeats: const [9],
              tripStream: Stream.value(t),
              onSeatToggle: (n) => tapped = n,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.bySemanticsLabel('Seat 1, free'), findsOneWidget);
    expect(find.bySemanticsLabel('Seat 2, taken'), findsOneWidget);
    expect(find.bySemanticsLabel('Seat 9, selected'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('1'));
    expect(tapped, 1);
    tapped = null;
    await tester.tap(find.byIcon(Icons.close)); // taken seat
    expect(tapped, isNull);
  });
}
