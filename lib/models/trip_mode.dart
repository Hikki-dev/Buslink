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
  // Sprint 1 Backlog Requirements:
  String platformNumber; // BL-13
  int delayMinutes;      // ADM-05
  TripStatus status;     // ADM-05
  final List<String> stops; // BL-03
  final List<int> bookedSeats;
  final int totalSeats;

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
  });

  bool get isFull => bookedSeats.length >= totalSeats;

  // Factory for Firestore
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
    );
  }

  // Mock Data Generator (For instant demo)
  static List<Trip> getMockTrips() {
    return [
      Trip(
        id: '1',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10)),
        price: 2800.0,
        operatorName: 'NCG Express',
        busNumber: 'NP-7788',
        busType: 'Super Luxury',
        stops: ['Colombo', 'Puttalam', 'Anuradhapura', 'Vavuniya', 'Jaffna'],
        bookedSeats: [1, 2, 5],
      ),
      Trip(
        id: '2',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        arrivalTime: DateTime.now().add(const Duration(hours: 11)),
        price: 2800.0,
        operatorName: 'Super Line',
        busNumber: 'ND-9900',
        busType: 'Luxury A/C',
        stops: ['Colombo', 'Jaffna'],
        bookedSeats: List.generate(40, (index) => index + 1), // FULL BUS (For BL-12 Demo)
      ),
       Trip(
        id: '3',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 5)),
        arrivalTime: DateTime.now().add(const Duration(hours: 13)),
        price: 2800.0,
        operatorName: 'Green Line',
        busNumber: 'NP-1234',
        busType: 'Super Luxury',
        stops: ['Colombo', 'Jaffna'],
        bookedSeats: [],
      ),
      Trip(
        id: '4',
        fromCity: 'Colombo',
        toCity: 'Badulla',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        arrivalTime: DateTime.now().add(const Duration(hours: 6)),
        price: 2200.0,
        operatorName: 'Hill Country',
        busNumber: 'UP-2020',
        busType: 'Luxury',
        stops: ['Colombo', 'Badulla'],
        bookedSeats: [],
        status: TripStatus.delayed, // ADM-05 Demo
        delayMinutes: 30,
      ),
    ];
  }
}