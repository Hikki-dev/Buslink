import 'package:buslink/controllers/trip_controller.dart';
import 'package:buslink/views/home/home_hero.dart';
import 'package:buslink/views/home/home_sections.dart';
import 'package:buslink/views/layout/app_footer.dart';
import 'package:buslink/views/layout/bl_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/app_fonts.dart';

class _Cities extends TripController {
  _Cities() {
    availableCities = ['Colombo', 'Kandy', 'Galle'];
  }
}

Widget _home(
  Size size, {
  required TextEditingController from,
  required TextEditingController to,
  bool bulk = false,
  VoidCallback? onSearch,
}) {
  final isDesktop = size.width > 900;
  return ChangeNotifierProvider<TripController>(
    create: (_) => _Cities(),
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [
              HomeHero(
                isDesktop: isDesktop,
                isAdminView: false,
                originController: from,
                destinationController: to,
                originFocusNode: FocusNode(),
                destinationFocusNode: FocusNode(),
                selectedDate: DateTime(2026, 11, 7),
                onDateTap: () {},
                onSearchTap: onSearch ?? () {},
                isBulkBooking: bulk,
                bulkDatesCount: 3,
                onBulkBookingChanged: (_) {},
              ),
              PopularJourneys(isDesktop: isDesktop, onPick: (_) {}),
              if (isDesktop) const HowItWorks(),
              if (isDesktop) const AppFooter(),
            ]),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(loadAppFonts);

  for (final size in [const Size(390, 844), const Size(1440, 1000)]) {
    testWidgets('home lays out without overflow at ${size.width.toInt()} px',
        (tester) async {
      final original = FlutterError.onError;
      final errs = <String>[];
      FlutterError.onError = (d) => errs.add(d.toString());
      addTearDown(() => FlutterError.onError = original);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final from = TextEditingController(text: 'Colombo');
      final to = TextEditingController(text: 'Kandy');
      await tester.pumpWidget(_home(size, from: from, to: to));
      await tester.pump(const Duration(milliseconds: 200));
      FlutterError.onError = original;
      if (errs.isNotEmpty) debugPrint(errs.first.substring(0, 1500));
      expect(errs, isEmpty);
      expect(find.text('Search Buses'), findsOneWidget);
      expect(find.text('Leaving from'), findsOneWidget);
      expect(find.text('Going to'), findsOneWidget);
      expect(find.text('Day of travel'), findsOneWidget);
      expect(
          find.textContaining('Popular journeys from Colombo'), findsOneWidget);
    });
  }

  testWidgets('swap button exchanges the two cities', (tester) async {
    final from = TextEditingController(text: 'Colombo');
    final to = TextEditingController(text: 'Kandy');
    await tester.pumpWidget(_home(const Size(390, 844), from: from, to: to));
    await tester.tap(find.bySemanticsLabel('Swap the two cities'));
    await tester.pump();
    expect(from.text, 'Kandy');
    expect(to.text, 'Colombo');
  });

  testWidgets('same city in both fields disables the search button',
      (tester) async {
    var searched = false;
    final from = TextEditingController(text: 'Kandy');
    final to = TextEditingController(text: 'kandy');
    await tester.pumpWidget(_home(const Size(390, 844),
        from: from, to: to, onSearch: () => searched = true));
    expect(find.text('Pick two different places'), findsOneWidget);
    await tester.tap(find.text('Pick two different places'));
    expect(searched, isFalse);
  });

  testWidgets('bottom bar marks the current page and reports taps',
      (tester) async {
    var tapped = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: BlBottomBar(
          currentIndex: 0,
          onTap: (i) => tapped = i,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.confirmation_number), label: 'My Trips'),
          ],
        ),
      ),
    ));
    await tester.tap(find.text('My Trips'));
    expect(tapped, 1);
  });

  test('journey time reads in plain words', () {
    expect(formatDuration(195), '3h 15m');
    expect(formatDuration(300), '5h');
    expect(formatDuration(45), '45m');
    expect(formatDuration(0), '');
  });
}
