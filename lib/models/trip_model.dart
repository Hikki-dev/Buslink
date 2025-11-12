import 'package:cloud_firestore/cloud_firestore.dart';

/// Trip Status Enum
enum TripStatus { onTime, delayed, cancelled }

/// Main Trip Model
/// Represents a bus journey with all booking details
class Trip {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final String operatorName;
  final String busNumber;
  final String busType; // e.g., "Super Luxury", "A/C"

  // Sprint 1 Requirements
  String platformNumber; // BL-13: Editable platform
  int delayMinutes; // ADM-05: Delay tracking
  TripStatus status; // ADM-05: Trip status management

  final List<String> stops; // BL-03: Route stops
  final List<int> bookedSeats; // Seat tracking
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

  /// Check if bus is full
  bool get isFull => bookedSeats.length >= totalSeats;

  /// Get available seats count
  int get availableSeats => totalSeats - bookedSeats.length;

  /// Get status badge color
  String get statusText {
    switch (status) {
      case TripStatus.onTime:
        return "On Time";
      case TripStatus.delayed:
        return "Delayed $delayMinutes min";
      case TripStatus.cancelled:
        return "Cancelled";
    }
  }

  /// Convert Firestore document to Trip object
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
      status: _parseStatus(data['status'] ?? 'onTime'),
      stops: List<String>.from(data['stops'] ?? []),
      bookedSeats: List<int>.from(data['bookedSeats'] ?? []),
      totalSeats: data['totalSeats'] ?? 40,
    );
  }

  /// Convert Trip to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fromCity': fromCity,
      'toCity': toCity,
      'departureTime': Timestamp.fromDate(departureTime),
      'arrivalTime': Timestamp.fromDate(arrivalTime),
      'price': price,
      'operatorName': operatorName,
      'busNumber': busNumber,
      'busType': busType,
      'platformNumber': platformNumber,
      'delayMinutes': delayMinutes,
      'status': status.name,
      'stops': stops,
      'bookedSeats': bookedSeats,
      'totalSeats': totalSeats,
    };
  }

  /// Parse status string to enum
  static TripStatus _parseStatus(String statusStr) {
    return TripStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => TripStatus.onTime,
    );
  }

  /// Mock data generator for testing (Sprint 1 demo)
  static List<Trip> getMockTrips() {
    return [
      // Colombo to Jaffna - Route 1 (On Time)
      Trip(
        id: 'mock_1',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10)),
        price: 2800.0,
        operatorName: 'NCG Express',
        busNumber: 'NP-7788',
        busType: 'Super Luxury',
        platformNumber: '4',
        stops: [
          'Colombo',
          'Negombo',
          'Puttalam',
          'Anuradhapura',
          'Vavuniya',
          'Jaffna',
        ],
        bookedSeats: [1, 2, 3, 4, 5],
      ),

      // Colombo to Jaffna - Route 2 (Delayed)
      Trip(
        id: 'mock_2',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 4)),
        arrivalTime: DateTime.now().add(const Duration(hours: 12)),
        price: 2800.0,
        operatorName: 'Yarl Devi Express',
        busNumber: 'ND-5544',
        busType: 'Luxury A/C',
        platformNumber: '5',
        status: TripStatus.delayed,
        delayMinutes: 30,
        stops: ['Colombo', 'Kurunegala', 'Vavuniya', 'Jaffna'],
        bookedSeats: [10, 11],
      ),

      // Colombo to Jaffna - Route 3 (Full Bus for BL-12 demo)
      Trip(
        id: 'mock_3',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        arrivalTime: DateTime.now().add(const Duration(hours: 9)),
        price: 2500.0,
        operatorName: 'Super Line',
        busNumber: 'ND-9900',
        busType: 'Standard A/C',
        platformNumber: '2',
        stops: ['Colombo', 'Jaffna'],
        bookedSeats: List.generate(40, (i) => i + 1), // Full bus
      ),

      // Colombo to Badulla (Available)
      Trip(
        id: 'mock_4',
        fromCity: 'Colombo',
        toCity: 'Badulla',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        arrivalTime: DateTime.now().add(const Duration(hours: 6)),
        price: 2200.0,
        operatorName: 'Hill Country Express',
        busNumber: 'UP-2020',
        busType: 'Super Luxury',
        platformNumber: '12',
        stops: ['Colombo', 'Avissawella', 'Ratnapura', 'Balangoda', 'Badulla'],
        bookedSeats: [],
      ),

      // Colombo to Kandy (Available)
      Trip(
        id: 'mock_5',
        fromCity: 'Colombo',
        toCity: 'Kandy',
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        arrivalTime: DateTime.now().add(const Duration(hours: 6)),
        price: 800.0,
        operatorName: 'Kandy Express',
        busNumber: 'CE-1234',
        busType: 'Luxury',
        platformNumber: '8',
        stops: ['Colombo', 'Kaduwela', 'Kegalle', 'Kandy'],
        bookedSeats: [7, 8, 15],
      ),
    ];
  }
}

/// Ticket Model for confirmed bookings
class Ticket {
  final String ticketId;
  final Trip trip;
  final List<int> seatNumbers;
  final String passengerName;
  final String passengerPhone;
  final DateTime bookingTime;
  final double totalAmount;
  final String paymentStatus; // PAID, PENDING, REFUNDED

  Ticket({
    required this.ticketId,
    required this.trip,
    required this.seatNumbers,
    required this.passengerName,
    required this.passengerPhone,
    required this.bookingTime,
    required this.totalAmount,
    this.paymentStatus = 'PAID',
  });

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId,
      'tripId': trip.id,
      'seatNumbers': seatNumbers,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'bookingTime': Timestamp.fromDate(bookingTime),
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
    };
  }

  /// Get QR data string
  String get qrData => '$ticketId-${trip.busNumber}-${seatNumbers.join(",")}';
}
