enum TripStatus { onTime, delayed, cancelled }

class Trip {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double price;
  final String operatorName;
  final String busType; // e.g., "Super Luxury"
  final String busNumber; // e.g., "ND-1234"
  String platformNumber; // Editable by Admin
  TripStatus status; // Editable by Admin
  int delayMinutes; // Editable by Admin
  final List<String> stops;
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
    required this.busType,
    required this.busNumber,
    this.platformNumber = "TBD",
    this.status = TripStatus.onTime,
    this.delayMinutes = 0,
    required this.stops,
    required this.bookedSeats,
    this.totalSeats = 40,
  });

  bool get isFull => bookedSeats.length >= totalSeats;

  // Factory for Mock Data (Sprint 1)
  static List<Trip> getMockTrips() {
    return [
      Trip(
        id: 'T1',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 2)),
        arrivalTime: DateTime.now().add(const Duration(hours: 10)),
        price: 2800.0,
        operatorName: 'NCG Express',
        busType: 'Super Luxury',
        busNumber: 'NP-7788',
        platformNumber: '4',
        stops: [
          'Colombo',
          'Negombo',
          'Puttalam',
          'Anuradhapura',
          'Vavuniya',
          'Jaffna',
        ],
        bookedSeats: [1, 2, 3, 4],
      ),
      Trip(
        id: 'T2',
        fromCity: 'Colombo',
        toCity: 'Jaffna',
        departureTime: DateTime.now().add(const Duration(hours: 4)),
        arrivalTime: DateTime.now().add(const Duration(hours: 12)),
        price: 2800.0,
        operatorName: 'Yarl Devi',
        busType: 'Luxury A/C',
        busNumber: 'ND-5544',
        platformNumber: '5',
        status: TripStatus.delayed,
        delayMinutes: 30,
        stops: ['Colombo', 'Kurunegala', 'Vavuniya', 'Jaffna'],
        bookedSeats: [],
      ),
      Trip(
        id: 'T3',
        fromCity: 'Colombo',
        toCity: 'Badulla',
        departureTime: DateTime.now().add(const Duration(hours: 1)),
        arrivalTime: DateTime.now().add(const Duration(hours: 6)),
        price: 2200.0,
        operatorName: 'Hill Country Express',
        busType: 'Super Luxury',
        busNumber: 'UP-2020',
        platformNumber: '12',
        stops: ['Colombo', 'Avissawella', 'Ratnapura', 'Balangoda', 'Badulla'],
        bookedSeats: List.generate(40, (index) => index + 1), // FULL BUS DEMO
      ),
      Trip(
        id: 'T4', // Alternative for T3
        fromCity: 'Colombo',
        toCity: 'Badulla',
        departureTime: DateTime.now().add(const Duration(hours: 3)),
        arrivalTime: DateTime.now().add(const Duration(hours: 8)),
        price: 2200.0,
        operatorName: 'Badulla Gun',
        busType: 'Luxury',
        busNumber: 'UP-9999',
        platformNumber: '12',
        stops: ['Colombo', 'Badulla'],
        bookedSeats: [],
      ),
    ];
  }
}

class Ticket {
  final String ticketId;
  final Trip trip;
  final List<int> seatNumbers;
  final String passengerName;
  final DateTime bookingTime;

  Ticket({
    required this.ticketId,
    required this.trip,
    required this.seatNumbers,
    required this.passengerName,
    required this.bookingTime,
  });
}
