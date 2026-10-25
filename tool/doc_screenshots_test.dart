// Regenerates the pictures in docs/images/ from the REAL app widgets, so the
// documentation always shows what the app looks like now.
//
//   flutter test tool/doc_screenshots_test.dart
//
// It is not part of `flutter test` (that only runs test/), and it needs no
// Firebase or network.
import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/l10n/app_localizations.dart';
import 'package:buslink/models/refund_model.dart';
import 'package:buslink/models/route_model.dart';
import 'package:buslink/models/schedule_model.dart';
import 'package:buslink/models/trip_model.dart';
import 'package:buslink/models/trip_view_model.dart';
import 'package:buslink/services/firestore_service.dart';
import 'package:buslink/utils/app_theme.dart';
import 'package:buslink/views/admin/widgets/status_chip.dart';
import 'package:buslink/views/booking/bus_layout_widget.dart';
import 'package:buslink/views/booking/my_trips_screen.dart';
import 'package:buslink/views/booking/payment_screen.dart';
import 'package:buslink/views/booking/refund_status_screen.dart';
import 'package:buslink/views/conductor/conductor_dashboard.dart';
import 'package:buslink/views/conductor/conductor_trip_management_screen.dart';
import 'package:buslink/views/results/bus_list_screen.dart';
import 'package:buslink/views/splash/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../test/helpers/app_fonts.dart';

/// The pictures use the app's own fonts (they are static files with real
/// weights) and the real Material icon font from the Flutter SDK.
Future<void> _loadDocFonts() async {
  await loadAppFonts();
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(
        File('$dir/MaterialIcons-Regular.otf').readAsBytesSync())));
  await icons.load();
}

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

Ticket _conductorTicket() => Ticket(
      ticketId: 'abc123',
      tripId: 'trip1',
      userId: 'u',
      seatNumbers: const [9, 10],
      passengerName: 'Nimal Perera',
      passengerPhone: '077',
      bookingTime: DateTime(2026, 11, 6),
      totalAmount: 2400,
      shortId: '4821',
      tripData: {
        'fromCity': 'Colombo',
        'toCity': 'Kandy',
        'busNumber': 'NP-1234',
        'departureDateTime': Timestamp.fromDate(DateTime(2026, 11, 7, 6, 30)),
        'arrivalDateTime': Timestamp.fromDate(DateTime(2026, 11, 7, 9, 45)),
        'price': 1200,
        'status': 'scheduled',
        'bookedSeatNumbers': ['9', '10', '3', '14'],
      },
    );

Ticket _pass() => Ticket(
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
        'status': 'scheduled',
        'departureDateTime':
            Timestamp.fromDate(DateTime.now().add(const Duration(hours: 2))),
      },
    );

final _shot = GlobalKey();

/// Draws [child] on white at phone width and saves it as docs/images/[name].
Future<void> _shoot(WidgetTester tester, String name, Widget child,
    {double width = 390, double? height}) async {
  tester.view.physicalSize = Size(width * 3, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Align(
        alignment: Alignment.topCenter,
        child: RepaintBoundary(
          key: _shot,
          child: Container(
              width: width,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: height == null
                  ? child
                  : SizedBox(height: height, child: child)),
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  // Three times the sharpness of the phone screen it imitates.
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shot));
  final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 3)))!;
  final bytes = (await tester
      .runAsync(() => image.toByteData(format: ui.ImageByteFormat.png)))!;
  File('docs/images/$name.png').writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  setUpAll(_loadDocFonts);

  testWidgets('bus-card', (tester) async {
    final normal = _trip();
    await _shoot(
        tester,
        'bus-card',
        ChangeNotifierProvider<TripController>(
          create: (_) => _FakeController(),
          child: Provider<FirestoreService>.value(
              value: _FakeService(normal.trip),
              child: BusTicketCard(trip: normal)),
        ),
        height: 395);
  });

  testWidgets('bus-card-delayed', (tester) async {
    final late = _trip(status: 'delayed', delay: 30, booked: 36);
    await _shoot(
        tester,
        'bus-card-delayed',
        ChangeNotifierProvider<TripController>(
          create: (_) => _FakeController(),
          child: Provider<FirestoreService>.value(
              value: _FakeService(late.trip), child: BusTicketCard(trip: late)),
        ),
        height: 440);

    await _shoot(tester, 'my-trips-card',
        BoardingPassCard(ticket: _pass(), shouldListen: false),
        height: 335);
  });

  testWidgets('seat-map', (tester) async {
    final seats = _trip(booked: 0).trip.copyWith(
        bookedSeatNumbers: const ['2', '3', '7', '8', '15', '16', '22', '30']);
    await _shoot(
        tester,
        'seat-map',
        BusLayoutWidget(
          trip: seats,
          totalSeats: 40,
          isDark: false,
          selectedSeats: const [9, 10],
          tripStream: Stream.value(seats),
          onSeatToggle: (_) {},
        ));
  });

  testWidgets('conductor-verified', (tester) async {
    final t = _conductorTicket();
    await _shoot(
        tester,
        'conductor-verified',
        TicketVerifiedCard(
          ticket: t,
          onApprove: () {},
          seatStream: Stream.value(Trip.fromMap(t.tripData, t.tripId)),
        ));
    await _shoot(
        tester,
        'conductor-already-boarded',
        TicketRejectedCard(
            title: 'Already boarded',
            message: alreadyBoardedMessage(DateTime(2026, 11, 7, 6, 31)),
            onClose: () {}));
    await _shoot(
        tester,
        'conductor-rejected',
        TicketRejectedCard(
            title: 'Ticket not accepted',
            message: 'Access Denied: Trip expired >12h ago',
            onClose: () {}));

    await _shoot(tester, 'delay-dialog', const DelayDialog());

    await _shoot(
        tester,
        'refund-progress',
        const Column(children: [
          RefundProgress(status: RefundStatus.pending),
          SizedBox(height: 24),
          RefundProgress(status: RefundStatus.approved),
          SizedBox(height: 24),
          RefundProgress(status: RefundStatus.rejected),
        ]));

    await _shoot(
        tester,
        'status-chips',
        const Wrap(spacing: 8, runSpacing: 8, children: [
          StatusChip('confirmed'),
          StatusChip('boarded'),
          StatusChip('cancelled'),
          StatusChip('refund_requested'),
          StatusChip('refunded'),
          StatusChip('pending'),
          StatusChip('approved'),
          StatusChip('rejected'),
          StatusChip('delayed'),
        ]));

    await _shoot(
        tester,
        'trip-form-steps',
        const Column(children: [
          TripFormSteps(current: 0),
          SizedBox(height: 20),
          TripFormSteps(current: 1),
          SizedBox(height: 20),
          TripFormSteps(current: 2),
        ]));
  });

  testWidgets('payment-states', (tester) async {
    await _shoot(
        tester,
        'payment-states',
        Column(children: [
          PaymentStateCard.verifying(),
          const SizedBox(height: 20),
          PaymentStateCard.failed(onHome: () {}, onSupport: () {}),
          const SizedBox(height: 20),
          PaymentStateCard.expired(onHome: () {}),
        ]));
  });

  // The start-up screens. Drawn with "reduce motion" on, which holds the
  // animation still: the bus parked at Kandy, two stops lit.
  void still(WidgetTester tester) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  testWidgets('splash', (tester) async {
    still(tester);
    await _shoot(tester, 'splash', const SplashScreen(), height: 700);
  });

  testWidgets('splash-slow', (tester) async {
    still(tester);
    await _shoot(tester, 'splash-slow', const SplashScreen(slow: true),
        height: 700);
  });

  testWidgets('startup-failed', (tester) async {
    await _shoot(tester, 'startup-failed', StartupFailedScreen(onRetry: () {}),
        height: 700);
  });
}
