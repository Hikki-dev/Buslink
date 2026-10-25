import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/views/results/bus_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/app_fonts.dart';

/// A controller that already "searched": no database, just what a search found.
class _Searched extends TripController {
  final Map<DateTime, int> days;
  String? searchedAgain;
  _Searched({this.days = const {}});

  @override
  Future<Map<DateTime, int>> upcomingDaysForRoute() async => days;

  @override
  Future<void> searchAgainOn(DateTime date) async {
    searchedAgain = '${date.year}-${date.month}-${date.day}';
  }
}

Future<void> _show(WidgetTester tester, _Searched c) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<TripController>.value(
    value: c,
    child: const MaterialApp(home: BusListScreen()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  _Searched searched(String from, String to, {Map<DateTime, int>? days}) =>
      _Searched(days: days ?? const {})
        ..fromCity = from
        ..toCity = to
        ..availableCities = ['Colombo', 'Kandy', 'Galle']
        ..isLoading = false
        ..tripDate = DateTime.now().add(const Duration(days: 3));

  testWidgets('a city we do not serve is named, with the cities that work',
      (tester) async {
    await _show(tester, searched('Gampola', 'Colombo'));
    expect(find.textContaining('We do not run buses to or from "Gampola"'),
        findsOneWidget);
    expect(find.textContaining('Colombo, Kandy, Galle'), findsOneWidget);
  });

  testWidgets('a known route with no buses that day offers other days',
      (tester) async {
    final next = DateTime.now().add(const Duration(days: 5));
    final day = DateTime(next.year, next.month, next.day);
    final c = searched('Kandy', 'Colombo', days: {day: 2});
    await _show(tester, c);
    expect(find.textContaining('No buses from Kandy to Colombo on'),
        findsOneWidget);
    expect(find.textContaining('2 buses'), findsOneWidget);
    await tester.tap(find.textContaining('2 buses'));
    expect(c.searchedAgain, '${day.year}-${day.month}-${day.day}');
  });

  testWidgets('no buses for two weeks says so', (tester) async {
    await _show(tester, searched('Kandy', 'Colombo'));
    expect(find.textContaining('no buses on this route in the next two weeks'),
        findsOneWidget);
  });

  testWidgets('today explains that buses which already left are hidden',
      (tester) async {
    final c = searched('Kandy', 'Colombo')..tripDate = DateTime.now();
    await _show(tester, c);
    expect(find.textContaining('already left today are not shown'),
        findsOneWidget);
  });
}
