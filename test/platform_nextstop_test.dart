import 'package:buslink/models/schedule_model.dart';
import 'package:buslink/models/trip_model.dart';
import 'package:buslink/utils/platform_text.dart';
import 'package:buslink/views/tracking/track_bus_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('platformOf hides unset values, including the old "TBD"', () {
    expect(platformOf({'platformNumber': '4'}), '4');
    expect(platformOf({'platformNumber': ' 12 '}), '12');
    expect(platformOf({'platformNumber': 'TBD'}), '');
    expect(platformOf({'platformNumber': 'tbd'}), '');
    expect(platformOf({}), '');
  });

  test('a schedule keeps its platform through save and load', () {
    final s = ScheduleModel(
        id: 's',
        routeId: 'r',
        busNumber: 'NP-1',
        operatorName: 'Op',
        busType: 'AC',
        amenities: const [],
        recurrenceDays: const [1],
        departureTime: '06:30',
        basePrice: 1200,
        totalSeats: 40,
        platform: '4');
    expect(ScheduleModel.fromMap(s.toJson(), 's').platform, '4');
    expect(ScheduleModel.fromMap({'routeId': 'r'}, 's').platform, '');
  });

  test('a trip reads its platform and ignores "TBD"', () {
    final base = {
      'scheduleId': 's',
      'originCity': 'Colombo',
      'destinationCity': 'Kandy',
    };
    expect(Trip.fromMap({...base, 'platformNumber': '7'}, 't').platform, '7');
    expect(Trip.fromMap({...base, 'platformNumber': 'TBD'}, 't').platform, '');
    expect(Trip.fromMap(base, 't').platform, '');
  });

  group('next stop', () {
    final dep = DateTime(2026, 11, 7, 6, 30);
    final arr = DateTime(2026, 11, 7, 9, 30); // 3 hours
    final stops = ['Colombo', 'Kegalle', 'Peradeniya', 'Kandy'];

    TripEta at(Duration after) => TripEta.compute(
        departure: dep, arrival: arr, delayMinutes: 0, now: dep.add(after));

    test('a third of the way: Peradeniya is next, a third of the trip away',
        () {
      final eta =
          at(const Duration(minutes: 70)); // 70/180 = 0.39, past Kegalle
      final next = nextStopAfter(stops, eta.progress, eta)!;
      expect(next.$1, 'Peradeniya');
      expect(next.$2.inMinutes, closeTo(50, 1)); // 2/3 of 180 = 120, minus 70
    });

    test('before the first stop: Kegalle is next', () {
      final eta = at(const Duration(minutes: 10));
      expect(nextStopAfter(stops, eta.progress, eta)!.$1, 'Kegalle');
    });

    test('after the last stop before the end: nothing to show', () {
      final eta = at(const Duration(minutes: 150));
      expect(nextStopAfter(stops, eta.progress, eta), isNull);
    });

    test('a route with no stops in between shows nothing', () {
      final eta = at(const Duration(minutes: 30));
      expect(nextStopAfter(['Colombo', 'Kandy'], eta.progress, eta), isNull);
      expect(nextStopAfter(const [], eta.progress, eta), isNull);
    });
  });
}
