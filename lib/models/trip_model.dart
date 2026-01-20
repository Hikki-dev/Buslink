// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus {
  scheduled,
  boarding,
  departed,
  cancelled,
  // Keeping some legacy statuses if needed by other parts of the app until full refactor
  started,
  inProgress,
  delayed,
  nearDestination,
  awaitingConfirmation,
  completed,
  onTime,
  arrived,
  onWay
}

class Trip {
  final String id;
  final String scheduleId; // Reference to schedules
  final DateTime date; // The specific operating date (e.g., 2026-01-10)
  final String originCity; // Denormalized from Route
  final String destinationCity; // Denormalized from Route
  final DateTime departureDateTime;
  final DateTime arrivalDateTime;
  final double price;
  final String status;
  final int totalSeats;
  final int delayMinutes;
  final List<String> bookedSeatNumbers; // The live seat map (Source of Truth)
  final Map<String, double>?
      currentLocation; // { "lat": double, "lng": double }
  final String? conductorId; // Denormalized from Schedule for easy query
  final String via; // Added via field

  // Legacy/Helper fields that might be useful or were in original model
  // We keep them if they don't conflict, but prioritize the strict schema.
  // The schema "DO NOT HALLUCINATE" instruction means strictly stick to what's provided + necessary helpers.
  // I will retain some fields if they seem critical for partial refactors (like operatorName for display)
  // BUUUT the prompt said: "Trip Model... generated from Schedules."
  // "Do not hallucinate fields not listed in the schema above."
  // So I should strictly follow the schema + minimal helpers.

  DateTime get departureTime => departureDateTime;
  DateTime get arrivalTime => arrivalDateTime;

  // Compatibility Getters
  String get fromCity => originCity;
  String get toCity => destinationCity;
  // String get via => 'Direct'; // REMOVED - Using field now
  String get duration =>
      "${arrivalDateTime.difference(departureDateTime).inHours}h ${arrivalDateTime.difference(departureDateTime).inMinutes % 60}m";
  String get operatorName => 'Buslink'; // Default
  String get busNumber => 'BUS-001'; // Default
  String get platformNumber => '1';
  int get blockedSeats => 0;
  List<String> get operatingDays => ['Daily'];

  Trip({
    required this.id,
    required this.scheduleId,
    required this.date,
    required this.originCity,
    required this.destinationCity,
    required this.departureDateTime,
    required this.arrivalDateTime,
    required this.price,
    this.status = 'Scheduled',
    this.totalSeats = 40,
    this.delayMinutes = 0,
    this.bookedSeatNumbers = const [],
    this.currentLocation,
    this.conductorId,
    this.via = 'Direct',
  });

  // CopyWith
  Trip copyWith({
    String? id,
    String? scheduleId,
    DateTime? date,
    String? originCity,
    String? destinationCity,
    DateTime? departureDateTime,
    DateTime? arrivalDateTime,
    double? price,
    String? status,
    int? totalSeats,
    int? delayMinutes,
    List<String>? bookedSeatNumbers,
    Map<String, double>? currentLocation,
    String? conductorId,
    String? via,
  }) {
    return Trip(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      date: date ?? this.date,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      departureDateTime: departureDateTime ?? this.departureDateTime,
      arrivalDateTime: arrivalDateTime ?? this.arrivalDateTime,
      price: price ?? this.price,
      status: status ?? this.status,
      totalSeats: totalSeats ?? this.totalSeats,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      bookedSeatNumbers: bookedSeatNumbers ?? this.bookedSeatNumbers,
      currentLocation: currentLocation ?? this.currentLocation,
      conductorId: conductorId ?? this.conductorId,
      via: via ?? this.via,
    );
  }

  // To Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'scheduleId': scheduleId,
      'date': Timestamp.fromDate(date),
      'originCity': originCity,
      'destinationCity': destinationCity,
      'departureDateTime': Timestamp.fromDate(departureDateTime),
      'arrivalDateTime': Timestamp.fromDate(arrivalDateTime),
      'price': price,
      'status': status,
      'totalSeats': totalSeats,
      'delayMinutes': delayMinutes,
      'bookedSeats': bookedSeatNumbers,
      'currentLocation': currentLocation,
      'conductorId': conductorId,
      'via': via,
    };
  }

  // From Firestore
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trip.fromMap(data, doc.id);
  }

  // From Map
  factory Trip.fromMap(Map<String, dynamic> data, String id) {
    return Trip(
      id: id,
      scheduleId: data['scheduleId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      originCity: data['originCity'] ?? data['fromCity'] ?? '',
      destinationCity: data['destinationCity'] ?? data['toCity'] ?? '',
      departureDateTime: (data['departureDateTime'] as Timestamp).toDate(),
      arrivalDateTime: (data['arrivalDateTime'] as Timestamp).toDate(),
      price: (data['price'] ?? 0).toDouble(),
      status: data['status'] ?? 'Scheduled',
      totalSeats: data['totalSeats'] ?? 40,
      delayMinutes: data['delayMinutes'] ?? 0,
      bookedSeatNumbers: List<String>.from(
          data['bookedSeatNumbers'] ?? data['bookedSeats'] ?? []),
      currentLocation: _parseGeoPoint(data['currentLocation']),
      conductorId: data['conductorId'],
      via: data['via'] ?? 'Direct',
    );
  }

  static Map<String, double>? _parseGeoPoint(dynamic val) {
    if (val == null) return null;
    if (val is GeoPoint) {
      return {'lat': val.latitude, 'lng': val.longitude};
    }
    if (val is Map) {
      return (val as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, (v as num).toDouble()),
      );
    }
    return null;
  }
}

// Keep Ticket Model as is, or remove if not requested.
// Usage usually requires Ticket to exist. I will keep it in the file if it was there,
// but for this specific rewrite I'm targeting TripModel.
// The file view showed Ticket was in the same file. I should keep it to avoid breaking other files yet.

class Ticket {
  final String ticketId;
  final String tripId;
  final String userId;
  final List<int> seatNumbers;
  final String passengerName;
  final String passengerPhone;
  final DateTime bookingTime;
  final double totalAmount;
  final Map<String, dynamic> tripData;
  final String status;
  final String? shortId;
  final String? paymentIntentId;
  final String? passengerEmail;
  final String? fcmToken; // Added to allow push without User read access

  Ticket({
    required this.ticketId,
    required this.tripId,
    required this.userId,
    required this.seatNumbers,
    required this.passengerName,
    required this.passengerPhone,
    this.passengerEmail,
    required this.bookingTime,
    required this.totalAmount,
    required this.tripData,
    this.status = 'confirmed',
    this.shortId,
    this.paymentIntentId,
    this.fcmToken,
  });

  factory Ticket.fromMap(Map<String, dynamic> data, String id) {
    return Ticket(
      ticketId: id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      seatNumbers: List<int>.from(data['seatNumbers'] ?? []),
      passengerName: data['userName'] ?? 'Guest',
      passengerPhone: data['passengerPhone'] ?? 'N/A',
      passengerEmail: data['passengerEmail'] ?? data['email'],
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      tripData: data['tripData'] as Map<String, dynamic>? ?? {},
      status: data['status'] ?? 'confirmed',
      shortId: data['shortId'],
      paymentIntentId: data['paymentIntentId'],
      fcmToken: data['fcmToken'],
    );
  }

  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Ticket.fromMap(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'tripId': tripId,
      'userId': userId,
      'seatNumbers': seatNumbers,
      'userName': passengerName,
      'passengerPhone': passengerPhone,
      'passengerEmail': passengerEmail,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'totalAmount': totalAmount,
      'tripData': tripData,
      'status': status,
      'shortId': shortId,
      'paymentIntentId': paymentIntentId,
      'fcmToken': fcmToken,
    };
  }
}
