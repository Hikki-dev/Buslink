import 'package:buslink/views/tracking/track_bus_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dep = DateTime(2026, 11, 7, 6, 30);
  final arr = DateTime(2026, 11, 7, 9, 45);

  test('halfway through the journey', () {
    final eta = TripEta.compute(
      departure: dep,
      arrival: arr,
      delayMinutes: 0,
      now: DateTime(2026, 11, 7, 8, 7, 30),
    );
    expect(eta.progress, closeTo(0.5, 0.001));
    expect(eta.remaining, const Duration(hours: 1, minutes: 37, seconds: 30));
    expect(eta.arrived, isFalse);
  });

  test('delay pushes the expected time and the minutes left', () {
    final eta = TripEta.compute(
      departure: dep,
      arrival: arr,
      delayMinutes: 30,
      now: DateTime(2026, 11, 7, 9, 45),
    );
    expect(eta.expected, DateTime(2026, 11, 7, 10, 15));
    expect(eta.remaining, const Duration(minutes: 30));
  });

  test('before departure and after arrival are clamped', () {
    final early = TripEta.compute(
        departure: dep,
        arrival: arr,
        delayMinutes: 0,
        now: dep.subtract(const Duration(hours: 1)));
    expect(early.progress, 0.0);
    final done = TripEta.compute(
        departure: dep,
        arrival: arr,
        delayMinutes: 0,
        now: arr.add(const Duration(hours: 1)));
    expect(done.progress, 1.0);
    expect(done.arrived, isTrue);
  });

  test('formatEta is plain', () {
    expect(formatEta(const Duration(seconds: 20)), 'Now');
    expect(formatEta(const Duration(minutes: 42)), '42 min');
    expect(formatEta(const Duration(hours: 1, minutes: 5)), '1 h 05 min');
  });
}
