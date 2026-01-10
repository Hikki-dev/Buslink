import '../models/trip_model.dart';
import '../models/schedule_model.dart';
import '../models/route_model.dart';

class EnrichedTrip {
  final Trip trip;
  final ScheduleModel schedule;
  final RouteModel route;

  EnrichedTrip({
    required this.trip,
    required this.schedule,
    required this.route,
  });

  // Proxy Getters for UI Compatibility
  String get id => trip.id;
  String get scheduleId => trip.scheduleId;
  DateTime get date => trip.date;
  String get status => trip.status;
  List<String> get bookedSeatNumbers => trip.bookedSeatNumbers;
  Map<String, double>? get currentLocation => trip.currentLocation;
  String get conductorId => trip.conductorId ?? schedule.conductorId ?? '';

  String get busNumber => schedule.busNumber;
  String get operatorName => schedule.operatorName;
  String get fromCity => trip.originCity;
  String get toCity => trip.destinationCity;
  String get originCity => trip.originCity;
  String get destinationCity => trip.destinationCity;
  DateTime get departureTime => trip.departureDateTime;
  DateTime get arrivalTime => trip.arrivalDateTime;
  double get price => trip.price;
  int get totalSeats => schedule.totalSeats;
  String get busType => schedule.busType;
  List<String> get amenities => schedule.amenities;
  List<String> get bookedSeats =>
      trip.bookedSeatNumbers; // Use bookedSeatNumbers
  int get delayMinutes => trip.delayMinutes;
  List<int> get operatingDays => schedule.recurrenceDays;

  // Computed Properties
  String get platformNumber => "1";

  // Route Proxies
  String get via => route.via;
  List<String> get stops => route.stops;
  int get durationMinutes => route.estimatedDurationMins;

  // Helpers
  Duration get duration => arrivalTime.difference(departureTime);
}
