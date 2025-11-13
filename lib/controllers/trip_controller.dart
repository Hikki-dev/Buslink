// lib/controllers/trip_controller.dart
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. IMPORT FIREBASE AUTH
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

  // --- 2. UPDATE THIS FUNCTION SIGNATURE ---
  Future<bool> processBooking(BuildContext context, User user) async {
    if (selectedTrip == null || selectedSeats.isEmpty) return false;

    _setLoading(true);
    try {
      currentTicket = await _service.processBooking(
        selectedTrip!,
        selectedSeats,
        user, // <-- Pass the user object
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

  // --- 3. ADD NEW FUNCTION TO GET USER'S TICKETS ---
  Stream<List<Ticket>> getUserTickets(String userId) {
    return _service.getUserTickets(userId);
  }

  // ... (rest of the file is unchanged) ...
  Future<void> fetchAllTripsForAdmin() async {
    _setLoading(true);
    try {
      allTripsForAdmin = await _service.getAllTrips();
    } catch (e) {
      allTripsForAdmin = [];
    }
    _setLoading(false);
  }

  Future<void> updatePlatform(String tripId, String newPlatform) async {
    await _service.updatePlatform(tripId, newPlatform);
    final index = allTripsForAdmin.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTripsForAdmin[index].platformNumber = newPlatform;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String tripId, TripStatus status, int delay) async {
    await _service.updateStatus(tripId, status, delay);
    final index = allTripsForAdmin.indexWhere((t) => t.id == tripId);
    if (index != -1) {
      allTripsForAdmin[index].status = status;
      allTripsForAdmin[index].delayMinutes = delay;
      notifyListeners();
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
