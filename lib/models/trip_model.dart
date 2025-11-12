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
  final String tripId; // <-- FIX: Changed from 'Trip trip'
  final List<int> seatNumbers;
  final String passengerName;
  final String passengerPhone; // <-- FIX: Kept this
  final DateTime bookingTime;
  final double totalAmount; // <-- FIX: Changed from 'amountPaid'

  Ticket({
    required this.ticketId,
    required this.tripId, // <-- FIX: Use tripId
    required this.seatNumbers,
    required this.passengerName,
    required this.passengerPhone, // <-- FIX: Add phone
    required this.bookingTime,
    required this.totalAmount, // <-- FIX: Use totalAmount
  });

  // <-- FIX: ADDED THIS ENTIRE METHOD
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'seatNumbers': seatNumbers,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'totalAmount': totalAmount,
    };
  }
}
