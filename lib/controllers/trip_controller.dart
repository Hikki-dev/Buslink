// lib/controllers/trip_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/firestore_service.dart';

class TripController extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? fromCity;
  String? toCity;
  DateTime? travelDate;

  List<Trip> searchResults = [];
  List<Trip> allTripsForAdmin = [];

  Trip? selectedTrip;
  List<int> selectedSeats = [];
  Ticket? currentTicket;

  bool isAdminMode = false;

  // --- 1. NEW PROPERTY FOR CONDUCTOR ---
  Trip? conductorSelectedTrip;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> searchTrips(BuildContext context) async {
    if (fromCity == null || toCity == null || travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select cities and date")),
      );
      return;
    }
    _setLoading(true);

    try {
      searchResults = await _service.searchTrips(
        fromCity!,
        toCity!,
        travelDate!,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      searchResults = [];
    }

    _setLoading(false);
  }

  Future<bool> processBooking(BuildContext context, User user) async {
    if (selectedTrip == null || selectedSeats.isEmpty) return false;

    _setLoading(true);
    try {
      currentTicket = await _service.processBooking(
        selectedTrip!,
        selectedSeats,
        user,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      _setLoading(false);
      return false;
    }
  }

  Stream<List<Ticket>> getUserTickets(String userId) {
    return _service.getUserTickets(userId);
  }

  Future<void> updateTripDetails(
    BuildContext context,
    String tripId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    try {
      data['departureTime'] = Timestamp.fromDate(data['departureTime']);
      data['arrivalTime'] = Timestamp.fromDate(data['arrivalTime']);

      await _service.updateTripDetails(tripId, data);

      // Add mounted check
      if (!context.mounted) return;
      await searchTrips(context); // This re-runs the search

      // Add another mounted check
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip updated successfully!")),
      );
      Navigator.pop(context); // Go back from AdminScreen
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating trip: ${e.toString()}")),
      );
    }
    _setLoading(false);
  }

  Future<void> fetchAllTripsForAdmin() async {
    _setLoading(true);
    try {
      allTripsForAdmin = await _service.getAllTrips();
    } catch (e) {
      allTripsForAdmin = [];
    }
    _setLoading(false);
  }

  // --- 2. NEW METHOD FOR CONDUCTOR TO FIND THEIR BUS ---
  Future<bool> findTripByBusNumber(
      BuildContext context, String busNumber) async {
    if (busNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a bus number")),
      );
      return false;
    }
    _setLoading(true);
    try {
      conductorSelectedTrip = await _service.getTripByBusNumber(busNumber);
      _setLoading(false);
      if (conductorSelectedTrip == null) {
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("No active trip found for that bus number.")),
        );
        return false;
      }
      return true;
    } catch (e) {
      _setLoading(false);
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
      return false;
    }
  }

  // --- 3. NEW METHOD FOR CONDUCTOR TO UPDATE STATUS (WITH FEEDBACK) ---
  Future<void> updateTripStatusAsConductor(
      BuildContext context, Trip trip, TripStatus status, int delay) async {
    _setLoading(true);
    try {
      await _service.updateStatus(trip.id, status, delay);

      // Update the local copy for the UI
      conductorSelectedTrip?.status = status;
      conductorSelectedTrip?.delayMinutes = delay;

      _setLoading(false);
      if (!context.mounted) return;

      // This is the feedback for the conductor
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success! Trip status set to ${status.name}.")),
      );
      notifyListeners(); // Update the UI on the management screen
    } catch (e) {
      _setLoading(false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

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
      fetchAllTripsForAdmin();
    }
    notifyListeners();
  }

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
