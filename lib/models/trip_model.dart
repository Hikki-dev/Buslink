// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus { onTime, delayed, cancelled }

class Trip {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final String operatorName;
  final String busNumber;
  final String busType;
  String platformNumber;
  int delayMinutes;
  TripStatus status;
  final List<String> stops;
  final List<int> bookedSeats;
  final int totalSeats;
  final List<String> features;

  Trip({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.operatorName,
    required this.busNumber,
    required this.busType,
    this.platformNumber = "TBD",
    this.delayMinutes = 0,
    this.status = TripStatus.onTime,
    required this.stops,
    required this.bookedSeats,
    this.totalSeats = 40,
    this.features = const [],
  });

  bool get isFull => bookedSeats.length >= totalSeats;

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      fromCity: data['fromCity'] ?? '',
      toCity: data['toCity'] ?? '',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      arrivalTime: (data['arrivalTime'] as Timestamp).toDate(),
      price: (data['price'] ?? 0).toDouble(),
      operatorName: data['operatorName'] ?? '',
      busNumber: data['busNumber'] ?? '',
      busType: data['busType'] ?? 'Standard',
      platformNumber: data['platformNumber'] ?? 'TBD',
      delayMinutes: data['delayMinutes'] ?? 0,
      status: TripStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'onTime'),
        orElse: () => TripStatus.onTime,
      ),
      stops: List<String>.from(data['stops'] ?? []),
      bookedSeats: List<int>.from(data['bookedSeats'] ?? []),
      totalSeats: data['totalSeats'] ?? 40,
      features: List<String>.from(data['features'] ?? []),
    );
  }
}

class Ticket {
  final String ticketId;
  final String tripId;
  final String userId; // <-- 1. ADD THIS FIELD
  final List<int> seatNumbers;
  final String passengerName;
  final String passengerPhone;
  final DateTime bookingTime;
  final double totalAmount;

  // --- 2. ADD 'tripData' FOR "MY TICKETS" PAGE ---
  // This is a copy of the trip info, so we don't have to load it separately
  final Map<String, dynamic> tripData;

  Ticket({
    required this.ticketId,
    required this.tripId,
    required this.userId, // <-- 3. ADD TO CONSTRUCTOR
    required this.seatNumbers,
    required this.passengerName,
    required this.passengerPhone,
    required this.bookingTime,
    required this.totalAmount,
    required this.tripData, // <-- 4. ADD TO CONSTRUCTOR
  });

  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'userId': userId, // <-- 5. ADD TO JSON
      'seatNumbers': seatNumbers,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'totalAmount': totalAmount,
      'tripData': tripData, // <-- 6. ADD TO JSON
    };
  }

  // --- 7. ADD A FACTORY FOR "MY TICKETS" PAGE ---
  factory Ticket.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Ticket(
      ticketId: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      seatNumbers: List<int>.from(data['seatNumbers'] ?? []),
      passengerName: data['passengerName'] ?? '',
      passengerPhone: data['passengerPhone'] ?? '',
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      tripData: Map<String, dynamic>.from(data['tripData'] ?? {}),
    );
  }
}
