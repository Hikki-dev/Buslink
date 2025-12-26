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

  // --- ADDED: getTodaysTrips ---
  Future<List<Trip>> getTodaysTrips() async {
    final now = DateTime.now();
    return getTripsForDate(now);
  }

  Future<List<Trip>> getTripsForDate(DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      return await _service.getTripsByDate(dayStart, dayEnd);
    } catch (e) {
      debugPrint("Error fetching trips for date $date: $e");
      return [];
    }
  }

  // --- ADDED: Add Trip ---
  Future<void> addTrip(BuildContext context, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      data['departureTime'] = Timestamp.fromDate(data['departureTime']);
      data['arrivalTime'] = Timestamp.fromDate(data['arrivalTime']);

      await _service.addTrip(data);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip added successfully!")),
      );
      Navigator.pop(context); // Close the add screen
      // Optionally refresh admin list
      if (isAdminMode) {
        // In a real app, you might want to refresh the search results if relevant
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding trip: $e")),
      );
    }
    _setLoading(false);
  }

  // --- ADDED: Add Route (Recurring) ---
  Future<void> addRoute(
    BuildContext context,
    Map<String, dynamic> routeData,
    List<int> recurrenceDays, // [1, 2, ... 7]
  ) async {
    _setLoading(true);
    try {
      // 1. Save Route Definition
      // We extract time of day components for storage
      final DateTime dep = routeData['departureTime'];
      final DateTime arr = routeData['arrivalTime'];

      final Map<String, dynamic> routeStorageData = {
        ...routeData,
        'departureTime': null, // Clear specific dates
        'arrivalTime': null,
        'departureHour': dep.hour,
        'departureMinute': dep.minute,
        'arrivalHour': arr.hour,
        'arrivalMinute': arr.minute,
        'recurrenceDays': recurrenceDays,
        'createdAt': FieldValue.serverTimestamp(),
      };
      final DocumentReference routeRef =
          await _service.addRoute(routeStorageData);
      debugPrint("Route created with ID: ${routeRef.id}");

      // 2. Generate Trips for next 90 days
      final int daysToGenerate = 90;
      final DateTime now = DateTime.now();

      // Calculate duration to maintain arrival time relative to departure
      final Duration tripDuration = arr.difference(dep);

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      int tripCount = 0;

      for (int i = 0; i < daysToGenerate; i++) {
        final DateTime targetDate = now.add(Duration(days: i));

        // Debug: check logic
        // debugPrint("Checking date: ${targetDate.toString()} Weekday: ${targetDate.weekday} vs Recurrence: $recurrenceDays");

        if (recurrenceDays.contains(targetDate.weekday)) {
          // Construct specific Departure Time
          final DateTime tripDeparture = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            dep.hour,
            dep.minute,
          );

          final DateTime tripArrival = tripDeparture.add(tripDuration);

          final DocumentReference newTripRef =
              FirebaseFirestore.instance.collection('trips').doc();

          final Map<String, dynamic> tripMap = {
            'operatorName': routeData['operatorName'],
            'busNumber': routeData['busNumber'],
            'busType': routeData['busType'],
            'fromCity': routeData['fromCity'],
            'toCity': routeData['toCity'],
            'departureTime': Timestamp.fromDate(tripDeparture),
            'arrivalTime': Timestamp.fromDate(tripArrival),
            'price': routeData['price'],
            'totalSeats': routeData['totalSeats'],
            'platformNumber': routeData['platformNumber'],
            'status': 'onTime', // Default
            'delayMinutes': 0,
            'bookedSeats': [],
            'features': routeData['features'],
            'stops': routeData['stops'],
            'via': routeData['via'] ?? '',
            'duration': routeData['duration'] ?? '',
            'operatingDays': routeData['operatingDays'] ?? [],
            'isGenerated': true,
            'routeId': routeRef.id, // Linked to the parent route
          };

          batch.set(newTripRef, tripMap);
          tripCount++;
        }
      }

      debugPrint("Batching $tripCount trips...");
      await batch.commit();
      debugPrint("Batch commit successful!");

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Route & $tripCount trips created!")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("ERROR in addRoute: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding route: $e")),
      );
    }
    _setLoading(false);
  }

  // --- ADDED: Delete Trip ---
  Future<void> deleteTrip(BuildContext context, String tripId) async {
    try {
      await _service.deleteTrip(tripId);

      // Remove from local lists to update UI immediately
      searchResults.removeWhere((t) => t.id == tripId);
      allTripsForAdmin.removeWhere((t) => t.id == tripId);
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip deleted successfully.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting trip: $e")),
        );
      }
    }
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

  // --- ADDED: Get Current/Next Active Ticket for Dashboard ---
  Stream<Ticket?> getCurrentActiveTicket(String userId) {
    return _service.getUserTickets(userId).map((tickets) {
      if (tickets.isEmpty) return null;

      final now = DateTime.now();
      // Filter filtering for non-cancelled and future/current trips is complex with dynamic status
      // We'll rely on time mostly + status check if available in tripData
      final activeTickets = tickets.where((t) {
        final status = t.tripData['status'] ?? 'scheduled';
        // Exclude cancelled or completed (past)
        if (status == 'cancelled' || status == 'completed') return false;

        // Check time
        DateTime? tripDate;
        if (t.tripData['departureTime'] is Timestamp) {
          tripDate = (t.tripData['departureTime'] as Timestamp).toDate();
        } else {
          tripDate = t.bookingTime; // Fallback
        }

        // Ideally show trips that haven't finished yet.
        // Approximate duration 4 hours if not set?
        // Let's just say if departure is after NOW - 6 hours (allowing for active trip)
        return tripDate.isAfter(now.subtract(const Duration(hours: 6)));
      }).toList();

      if (activeTickets.isEmpty) return null;

      // Sort by earliest departure
      activeTickets.sort((a, b) {
        DateTime dateA = (a.tripData['departureTime'] as Timestamp).toDate();
        DateTime dateB = (b.tripData['departureTime'] as Timestamp).toDate();
        return dateA.compareTo(dateB);
      });

      return activeTickets.first;
    });
  }

  // --- FAVORITES ---
  Future<void> toggleFavorite(String userId, Trip trip) async {
    await _service.toggleFavorite(userId, trip);
    notifyListeners();
  }

  Future<bool> isTripFavorite(String userId, String tripId) {
    return _service.isTripFavorite(userId, tripId);
  }

  Stream<List<Map<String, dynamic>>> getUserFavorites(String userId) {
    return _service.getUserFavorites(userId);
  }

  // Route Favorites
  Future<void> toggleRouteFavorite(
      String userId, String fromCity, String toCity) async {
    await _service.toggleRouteFavorite(userId, fromCity, toCity);
    notifyListeners();
  }

  Future<bool> isRouteFavorite(String userId, String fromCity, String toCity) {
    return _service.isRouteFavorite(userId, fromCity, toCity);
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

      if (!context.mounted) return;
      // If search results are active, refresh them manually or just notify
      // Ideally we fetch again, but for now we let the user navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip updated successfully!")),
      );
      Navigator.pop(context);
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

  Future<bool> findTripByBusNumber(
      BuildContext context, String busNumber) async {
    // ... existing code ...
    // Note: Conductor view is now static, but we keep this logic intact for reference.
    if (busNumber.isEmpty) return false;
    _setLoading(true);
    try {
      conductorSelectedTrip = await _service.getTripByBusNumber(busNumber);
      _setLoading(false);
      if (conductorSelectedTrip == null) {
        return false;
      }
      return true;
    } catch (e) {
      _setLoading(false);
      return false;
    }
  }

  Future<void> updateTripStatusAsConductor(
      BuildContext context, Trip trip, TripStatus status, int delay) async {
    _setLoading(true);
    try {
      // In static mode this might fail if trip doesn't exist in DB, but keeping logic for robustness
      if (trip.id != "static_trip_id") {
        await _service.updateStatus(trip.id, status, delay);
      }

      conductorSelectedTrip?.status = status;
      conductorSelectedTrip?.delayMinutes = delay;

      _setLoading(false);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success! Trip status set to ${status.name}.")),
      );
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      // Swallow error for static mode demo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated (Simulation): ${status.name}")),
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

  // --- User Management ---
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _service.getAllUsers();
  }

  // --- Ticket Verification ---
  Future<Ticket?> verifyTicket(String ticketId) async {
    return await _service.getTicket(ticketId);
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _service.updateUserRole(uid, newRole);
    notifyListeners();
  }
}
