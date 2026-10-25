import 'package:buslink/models/trip_model.dart';
import 'package:buslink/views/booking/bus_layout_widget.dart';
import 'package:buslink/views/layout/bl_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Trip _trip() => Trip(
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
    );

void main() {
  testWidgets('a screen reader can choose a seat', (tester) async {
    final handle = tester.ensureSemantics();
    final chosen = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: BusLayoutWidget(
            trip: _trip(),
            isDark: false,
            tripStream: Stream.value(_trip()),
            onSeatToggle: chosen.add,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel('Seat 9, free'));
    expect(chosen, [9]);
    handle.dispose();
  });

  testWidgets('a screen reader can switch tabs', (tester) async {
    final handle = tester.ensureSemantics();
    int? picked;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BlBottomBar(
          currentIndex: 0,
          onTap: (i) => picked = i,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.favorite), label: 'Favorites'),
          ],
        ),
      ),
    ));
    tester.semantics.tap(find.semantics.byLabel('Favorites'));
    expect(picked, 1);
    handle.dispose();
  });
}
