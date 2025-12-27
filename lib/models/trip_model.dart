// lib/models/trip_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum TripStatus {
  scheduled,
  boarding,
  departed,
  delayed,
  cancelled,
  completed,
  onTime,
  arrived,
  onWay
}

class Trip {
  final String id;
  final String operatorName;
  final String busNumber;
  final String fromCity;
  final String toCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final int totalSeats;
  final String platformNumber;
  TripStatus status;
  int delayMinutes;
  final List<int> bookedSeats;
  final List<String> stops;
  final String via;
  final String duration;
  final List<int> operatingDays;
  final bool isGenerated;
  final String? routeId;
  final List<int> blockedSeats;

  Trip({
    required this.id,
    required this.operatorName,
    required this.busNumber,
    required this.fromCity,
    required this.toCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    required this.totalSeats,
    required this.platformNumber,
    this.status = TripStatus.scheduled,
    this.delayMinutes = 0,
    required this.bookedSeats,
    required this.stops,
    this.via = '',
    this.duration = '',
    this.operatingDays = const [],
    this.isGenerated = false,
    this.routeId,
    this.blockedSeats = const [],
  });

  bool get isFull => bookedSeats.length + blockedSeats.length >= totalSeats;

  // --- ADDED: toMap for serialization ---
  Map<String, dynamic> toMap() {
    return {
      'operatorName': operatorName,
      'busNumber': busNumber,
      'fromCity': fromCity,
      'toCity': toCity,
      'departureTime': Timestamp.fromDate(departureTime),
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'price': price,
      'totalSeats': totalSeats,
      'platformNumber': platformNumber,
      'status': status.name,
      'delayMinutes': delayMinutes,
      'bookedSeats': bookedSeats,
      'stops': stops,
      'via': via,
      'duration': duration,
      'operatingDays': operatingDays,
      'isGenerated': isGenerated,
      'routeId': routeId,
      'blockedSeats': blockedSeats,
    };
  }

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      operatorName: data['operatorName'] ?? '',
      busNumber: data['busNumber'] ?? '',
      fromCity: data['fromCity'] ?? '',
      toCity: data['toCity'] ?? '',
      departureTime: (data['departureTime'] as Timestamp).toDate(),
      arrivalTime: (data['arrivalTime'] as Timestamp).toDate(),
      price: (data['price'] ?? 0).toDouble(),
      totalSeats: data['totalSeats'] ?? 0,
      platformNumber: data['platformNumber'] ?? 'TBD',
      status: TripStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'scheduled'),
        orElse: () => TripStatus.scheduled,
      ),
      delayMinutes: data['delayMinutes'] ?? 0,
      bookedSeats: List<int>.from(data['bookedSeats'] ?? []),
      stops: List<String>.from(data['stops'] ?? []),
      via: data['via'] ?? '',
      duration: data['duration'] ?? '',
      operatingDays: List<int>.from(data['operatingDays'] ?? []),
      isGenerated: data['isGenerated'] ?? false,
      routeId: data['routeId'],
      blockedSeats: List<int>.from(data['blockedSeats'] ?? []),
    );
  }
}

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

  Ticket({
    required this.ticketId,
    required this.tripId,
    required this.userId,
    required this.seatNumbers,
    required this.passengerName,
    required this.passengerPhone,
    required this.bookingTime,
    required this.totalAmount,
    required this.tripData,
    this.status = 'confirmed',
  });

  // --- ADDED: fromMap for deserialization ---
  factory Ticket.fromMap(Map<String, dynamic> data, String id) {
    return Ticket(
      ticketId: id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      seatNumbers: List<int>.from(data['seatNumbers'] ?? []),
      passengerName: data['userName'] ?? 'Guest', // Mapped from 'userName'
      passengerPhone: data['passengerPhone'] ?? 'N/A', // Potentially missing
      bookingTime: (data['bookingTime'] as Timestamp).toDate(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      tripData: data['tripData'] as Map<String, dynamic>? ?? {},
      status: data['status'] ?? 'confirmed',
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
      'bookingTime': Timestamp.fromDate(bookingTime),
      'totalAmount': totalAmount,
      'tripData': tripData,
      'status': status,
    };
  }
}
