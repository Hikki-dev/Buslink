import 'package:flutter/material.dart';
import '../models/bus_model.dart';

class AppController extends ChangeNotifier {
  // === STATE ===
  bool isLoading = false;
  List<Trip> allTrips = Trip.getMockTrips(); // In real app, fetch from Firebase
  List<Trip> searchResults = [];

  // Search Inputs
  String? fromCity;
  String? toCity;
  DateTime? travelDate;

  // Booking Flow
  Trip? selectedTrip;
  List<int> selectedSeats = [];
  Ticket? currentTicket;

  // Admin Logic
  bool isAdminMode = false;

  // === ACTIONS ===

  // BL-01: Search Validation & Logic
  Future<void> searchBuses(BuildContext context) async {
    if (fromCity == null || toCity == null || travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select Origin, Destination, and Date"),
        ),
      );
      return;
    }

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Simulating API

    // Filter logic
    searchResults = allTrips.where((trip) {
      return trip.fromCity == fromCity && trip.toCity == toCity;
      // Date check omitted for Sprint 1 demo simplicity to ensure data shows up
    }).toList();

    isLoading = false;
    notifyListeners();
  }

  // BL-12: Alternative Suggestions
  List<Trip> getAlternativeTrips(Trip fullTrip) {
    // Logic: Find same route, later time
    return allTrips
        .where(
          (t) =>
              t.fromCity == fullTrip.fromCity &&
              t.toCity == fullTrip.toCity &&
              t.id != fullTrip.id &&
              !t.isFull,
        )
        .take(3)
        .toList();
  }

  void selectTrip(Trip trip) {
    selectedTrip = trip;
    selectedSeats.clear();
    notifyListeners();
  }

  void toggleSeat(int seatNum) {
    if (selectedSeats.contains(seatNum)) {
      selectedSeats.remove(seatNum);
    } else {
      selectedSeats.add(seatNum);
    }
    notifyListeners();
  }

  // BL-06 & BL-19: Booking & Payment Mock
  Future<void> confirmBooking(BuildContext context) async {
    if (selectedSeats.isEmpty) return;

    isLoading = true;
    notifyListeners();

    await Future.delayed(
      const Duration(seconds: 2),
    ); // Simulating Payment Gateway

    // Create Ticket
    currentTicket = Ticket(
      ticketId:
          "BL-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
      trip: selectedTrip!,
      seatNumbers: List.from(selectedSeats),
      passengerName: "Saman Perera", // Mock User
      bookingTime: DateTime.now(),
    );

    isLoading = false;
    notifyListeners();
  }

  // ADM-05: Conductor/Admin Updates
  void updateTripStatus(String tripId, TripStatus newStatus, int delay) {
    final index = allTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTrips[index].status = newStatus;
      allTrips[index].delayMinutes = delay;
      notifyListeners();
    }
  }

  // ADM-14: Platform Update
  void updatePlatform(String tripId, String platform) {
    final index = allTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTrips[index].platformNumber = platform;
      notifyListeners();
    }
  }

  void toggleAdminMode() {
    isAdminMode = !isAdminMode;
    notifyListeners();
  }
}
