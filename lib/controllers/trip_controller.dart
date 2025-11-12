// lib/controllers/trip_controller.dart
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/firestore_service.dart'; // <-- IMPORT THE SERVICE

class TripController extends ChangeNotifier {
  final FirestoreService _service = FirestoreService(); // <-- USE THE SERVICE

  // --- STATE ---
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // UI state
  String? fromCity;
  String? toCity;
  DateTime? travelDate;

  // Data state
  List<Trip> searchResults = []; // No mock data!
  List<Trip> allTripsForAdmin = []; // For admin panel

  // Booking state
  Trip? selectedTrip;
  List<int> selectedSeats = [];
  Ticket? currentTicket; // For the ticket screen

  // Admin Toggle (ADM-01)
  bool isAdminMode = false;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- USER ACTIONS ---

  // BL-01: Search Logic (Refactored)
  Future<void> searchTrips(BuildContext context) async {
    if (fromCity == null || toCity == null || travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select cities and date")),
      );
      return;
    }
    _setLoading(true);

    try {
      // Call the service!
      searchResults = await _service.searchTrips(
        fromCity!,
        toCity!,
        travelDate!,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      searchResults = [];
    }

    _setLoading(false);
  }

  // BL-19: Payment Mock (Refactored)
  Future<bool> processBooking(BuildContext context) async {
    if (selectedTrip == null || selectedSeats.isEmpty) return false;

    _setLoading(true);
    try {
      // Call the service
      currentTicket = await _service.processBooking(
        selectedTrip!,
        selectedSeats,
        "Saman Perera", // Mock user, get from auth later
      );
      _setLoading(false);
      return true; // Success
    } catch (e) {
      print("Booking Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      _setLoading(false);
      return false; // Failed
    }
  }

  // --- ADMIN ACTIONS (Refactored) ---

  // Helper to get all trips for the admin panel
  Future<void> fetchAllTripsForAdmin() async {
    _setLoading(true);
    try {
      allTripsForAdmin = await _service.getAllTrips();
    } catch (e) {
      allTripsForAdmin = [];
    }
    _setLoading(false);
  }

  // ADM-14: Update Platform
  Future<void> updatePlatform(String tripId, String newPlatform) async {
    await _service.updatePlatform(tripId, newPlatform);

    // Update local list to refresh UI
    final index = allTripsForAdmin.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTripsForAdmin[index].platformNumber = newPlatform;
      notifyListeners();
    }
  }

  // ADM-05: Update Status
  Future<void> updateStatus(String tripId, TripStatus status, int delay) async {
    await _service.updateStatus(tripId, status, delay);

    // Update local list
    final index = allTripsForAdmin.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTripsForAdmin[index].status = status;
      allTripsForAdmin[index].delayMinutes = delay;
      notifyListeners();
    }
  }

  // --- Local UI Helper Methods (These stay the same) ---

  void selectTrip(Trip trip) {
    selectedTrip = trip;
    selectedSeats.clear();
    notifyListeners();
  }

  void toggleSeat(int seatNumber) {
    if (selectedSeats.contains(seatNumber)) {
      selectedSeats.remove(seatNumber);
    } else {
      selectedSeats.add(seatNumber);
    }
    notifyListeners();
  }

  void setFromCity(String? city) {
    fromCity = city;
    notifyListeners();
  }

  void setToCity(String? city) {
    toCity = city;
    notifyListeners();
  }

  void setDate(DateTime? date) {
    travelDate = date;
    notifyListeners();
  }

  void toggleAdminMode() {
    isAdminMode = !isAdminMode;
    if (isAdminMode) {
      fetchAllTripsForAdmin(); // Fetch admin data when mode is enabled
    }
    notifyListeners();
  }

  // BL-12: Alternative Suggestions
  List<Trip> getAlternatives(Trip fullOrCancelledTrip) {
    return searchResults
        .where(
          (t) =>
              t.id != fullOrCancelledTrip.id &&
              !t.isFull &&
              t.status != TripStatus.cancelled,
        )
        .take(3)
        .toList();
  }
}
