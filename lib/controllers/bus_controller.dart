import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class BusController extends ChangeNotifier {
  
  // State
  bool isLoading = false;
  List<Trip> allTrips = Trip.getMockTrips(); // Using Mock for Demo if DB not connected
  List<Trip> searchResults = [];
  
  // Inputs
  String? fromCity;
  String? toCity;
  DateTime? travelDate;

  // Booking State
  List<int> selectedSeats = [];
  Trip? currentTrip;

  // Admin Toggle (ADM-01)
  bool isAdminMode = false;

  // --- USER ACTIONS ---

  Future<void> searchTrips(BuildContext context) async {
    if (fromCity == null || toCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select cities")));
      return;
    }

    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Simulate API

    // BL-01: Search Logic
    searchResults = allTrips.where((t) => 
      t.fromCity == fromCity && 
      t.toCity == toCity
    ).toList();

    isLoading = false;
    notifyListeners();
  }

  // BL-12: Alternative Suggestions
  List<Trip> getAlternatives(Trip fullTrip) {
    return allTrips.where((t) => 
      t.fromCity == fullTrip.fromCity && 
      t.toCity == fullTrip.toCity && 
      t.id != fullTrip.id &&
      !t.isFull
    ).take(3).toList();
  }

  void selectTrip(Trip trip) {
    currentTrip = trip;
    selectedSeats.clear();
    notifyListeners();
  }

  void toggleSeat(int seat) {
    if (selectedSeats.contains(seat)) {
      selectedSeats.remove(seat);
    } else {
      selectedSeats.add(seat);
    }
    notifyListeners();
  }

  // BL-19: Payment Mock
  Future<bool> processBooking() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2)); // Payment gateway
    isLoading = false;
    notifyListeners();
    return true; // Success
  }

  // --- ADMIN ACTIONS (ADM-02, ADM-05, ADM-14) ---

  void toggleAdmin() {
    isAdminMode = !isAdminMode;
    notifyListeners();
  }

  // ADM-14: Update Platform
  void updatePlatform(String tripId, String newPlatform) {
    final index = allTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTrips[index].platformNumber = newPlatform;
      notifyListeners();
    }
  }

  // ADM-05: Update Status
  void updateStatus(String tripId, TripStatus status, int delay) {
    final index = allTrips.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTrips[index].status = status;
      allTrips[index].delayMinutes = delay;
      notifyListeners();
    }
  }
}