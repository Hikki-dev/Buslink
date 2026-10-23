import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/models/route_model.dart';
import 'package:buslink/models/schedule_model.dart';
import 'package:buslink/models/trip_model.dart';
import 'package:buslink/models/trip_view_model.dart';
import 'package:buslink/views/booking/payment_screen.dart';
import 'package:buslink/views/results/bus_details_screen.dart';
import 'package:buslink/views/widgets/bl_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/app_fonts.dart';

EnrichedTrip _trip() => EnrichedTrip(
      trip: Trip(
        id: 't',
        scheduleId: 's',
        date: DateTime(2026, 11, 7),
        originCity: 'Colombo',
        destinationCity: 'Kandy',
        departureDateTime: DateTime(2026, 11, 7, 6, 30),
        arrivalDateTime: DateTime(2026, 11, 7, 9, 45),
        price: 1200,
        status: 'scheduled',
        delayMinutes: 0,
        totalSeats: 40,
        bookedSeatNumbers: const [],
      ),
      schedule: ScheduleModel(
          id: 's',
          routeId: 'r',
          busNumber: 'NP-1234',
          operatorName: 'SuperLine Express',
          busType: 'Luxury AC',
          amenities: const ['Air conditioning', 'WiFi'],
          recurrenceDays: const [1],
          departureTime: '06:30',
          basePrice: 1200,
          totalSeats: 40),
      route: RouteModel(
          id: 'r',
          originCity: 'Colombo',
          destinationCity: 'Kandy',
          via: '',
          stops: const ['Colombo', 'Kadawatha', 'Kegalle', 'Kandy'],
          distanceKm: 115,
          estimatedDurationMins: 195,
          isActive: true),
    );

void main() {
  setUpAll(loadAppFonts);

  testWidgets('payment states say what happened and offer the way on',
      (tester) async {
    var home = 0, support = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            PaymentStateCard.failed(
                onHome: () => home++, onSupport: () => support++),
            PaymentStateCard.expired(onHome: () => home++),
          ]),
        ),
      ),
    ));
    expect(find.text('Verification Failed'), findsOneWidget);
    expect(find.textContaining('Your seats are not lost'), findsOneWidget);
    expect(find.text('Session Expired'), findsOneWidget);
    await tester.tap(find.text('Contact support'));
    await tester.tap(find.text('Go Home'));
    await tester.tap(find.text('Return to Home'));
    expect(support, 1);
    expect(home, 2);
  });

  testWidgets('bus details lists the stops and what is on the bus',
      (tester) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider<TripController>(
      create: (_) => TripController(),
      child: MaterialApp(home: BusDetailsScreen(trip: _trip())),
    ));
    expect(find.text('SuperLine Express'), findsOneWidget);
    expect(find.text('Air conditioning'), findsOneWidget);
    expect(find.text('Kadawatha · Kegalle'), findsOneWidget);
    expect(find.text('06:30 AM'), findsOneWidget);
    expect(find.text('Choose seats'), findsOneWidget);
  });

  testWidgets('booking steps mark done, current and next', (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: BookingSteps(current: 1))));
    expect(find.text('Choose a bus'), findsOneWidget);
    expect(find.text('Choose seats'), findsOneWidget);
    expect(find.text('Pay and get your ticket'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget); // step 1 done
  });
}
