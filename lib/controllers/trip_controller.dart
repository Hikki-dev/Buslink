import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../models/schedule_model.dart';
import '../models/route_model.dart'; // Added
import '../models/trip_view_model.dart'; // EnrichedTrip
import '../services/firestore_service.dart';

class TripController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Search State
  List<EnrichedTrip> searchResults = [];
  bool isLoading = false;
  String? error;

  // Selected Trip State
  // Selected Trip State
  EnrichedTrip? selectedTrip;

  // Search Params (UI Persistence)
  String? fromCity;
  String? toCity;
  DateTime? tripDate;

  void setFromCity(String val) {
    fromCity = val;
    notifyListeners();
  }

  void setToCity(String val) {
    toCity = val;
    notifyListeners();
  }

  void setDate(DateTime val) {
    tripDate = val;
    notifyListeners();
  }

  // Cache for Schedules & Routes to avoid N+1
  final Map<String, ScheduleModel> _scheduleCache = {};
  final Map<String, RouteModel> _routeCache = {};

  // --- TRIP SEARCH & ENRICHMENT ---

  /// Searches trips and enriches them with Schedule data.
  Future<void> searchTrips(String from, String to, DateTime date) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      // 1. Fetch Trips (Instances)
      final trips = await _firestoreService.searchTrips(from, to, date);

      // 2. Enrich (Fetch Schedules)
      searchResults = await enrichTrips(trips);

      notifyListeners();
    } catch (e) {
      error = e.toString();
      debugPrint("Error searching trips: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Helper to merge Trip instance with Schedule template
  Future<List<EnrichedTrip>> enrichTrips(List<Trip> trips) async {
    final List<EnrichedTrip> enriched = [];

    // 1. Collect unique Schedule IDs
    final scheduleIds = trips.map((t) => t.scheduleId).toSet();

    // 2. Fetch missing Schedules
    // Optimization: Could use Future.wait, but simple loop with cache check is vastly better than before
    for (var id in scheduleIds) {
      if (!_scheduleCache.containsKey(id)) {
        final schedule = await _firestoreService.getScheduleForTrip(id);
        if (schedule != null) {
          _scheduleCache[id] = schedule;
        }
      }
    }

    // 3. Collect unique Route IDs from the Schedules we just ensured we have
    final Set<String> routeIds = {};
    for (var id in scheduleIds) {
      final sch = _scheduleCache[id];
      if (sch != null) routeIds.add(sch.routeId);
    }

    // 4. Fetch missing Routes
    for (var rid in routeIds) {
      if (!_routeCache.containsKey(rid)) {
        final route = await _firestoreService.getRoute(rid);
        if (route != null) {
          _routeCache[rid] = route;
        }
      }
    }

    // 5. Build Result synchronously (Memory lookup)
    for (var trip in trips) {
      final schedule = _scheduleCache[trip.scheduleId];
      if (schedule != null) {
        final route = _routeCache[schedule.routeId];
        if (route != null) {
          enriched
              .add(EnrichedTrip(trip: trip, schedule: schedule, route: route));
        } else {
          // Route missing?
        }
      } else {
        // Schedule missing?
      }
    }
    return enriched;
  }

  // --- CONDUCTOR METHODS ---

  List<EnrichedTrip> conductorTrips = [];

  Future<void> getTripsByConductor(String conductorId) async {
    try {
      isLoading = true;
      notifyListeners();

      final trips = await _firestoreService.getTripsByConductor(conductorId);
      conductorTrips = await enrichTrips(trips);
    } catch (e) {
      // print("Error getting conductor trips: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(
      String tripId, TripStatus status, int delayMinutes) async {
    await _firestoreService.updateStatus(tripId, status, delayMinutes);
    // Refresh if needed
  }

  // --- BOOKING ---

  Future<Ticket> processBooking(EnrichedTrip enrichedTrip, List<String> seatIds,
      Map<String, dynamic> userDetails) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    // Pass Enriched details (denormalized) to ticket for history
    final extraDetails = enrichedTrip.trip.toJson();
    extraDetails['busNumber'] = enrichedTrip.busNumber;
    extraDetails['operatorName'] = enrichedTrip.operatorName;
    extraDetails['scheduleId'] = enrichedTrip.schedule.id;

    return await _firestoreService.processBooking(
        enrichedTrip.trip, seatIds, currentUser, extraDetails);
  }

  // Legacy wrappers for compilation compatibility
  // If UI calls with `Trip` object (e.g. from a stream), we might need to handle it.
  // But preferably UI uses EnrichedTrip.

  Future<String> createPendingBooking(
      EnrichedTrip enrichedTrip, List<String> seatIds) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception("User not logged in");

    return await _firestoreService.createPendingBooking(
        enrichedTrip.trip, seatIds, currentUser);
  }

  // --- FAVORITES ---

  Future<void> toggleFavorite(EnrichedTrip enrichedTrip) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.toggleFavorite(uid, enrichedTrip.trip);
  }

  Future<bool> isTripFavorite(String tripId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return await _firestoreService.isTripFavorite(uid, tripId);
  }

  Future<void> removeFavorite(String tripId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.removeFavorite(uid, tripId);
  }

  // --- CITIES ---

  Future<List<String>> getAvailableCities() async {
    return _firestoreService.getAvailableCities();
  }

  // --- UTILS ---

  // Methods for real-time updates (Stream)
  // Ideally streams should emit EnrichedTrip, but that requires async mapping inside stream.
  // For now, simpler to return Stream<Trip> and let UI fetch schedule or use simplified view.
  // However, simpler is to just define the missing getters in the UI or fetch helper.

  // If UI depends on Stream<List<Trip>>, we can't easily enrich inside Stream without rxdart.
  // Given urgency, I will expose Stream<List<Trip>> and assumes UI handles plain Trip
  // OR standardizes on `searchResults` (provider).

  Stream<EnrichedTrip?> getTripRealtimeStream(String tripId) {
    return FirebaseFirestore.instance
        .collection('trips')
        .doc(tripId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return null;
      final trip = Trip.fromFirestore(doc);

      // Simple cache check/fetch since this is single item stream
      if (!_scheduleCache.containsKey(trip.scheduleId)) {
        final schedule =
            await _firestoreService.getScheduleForTrip(trip.scheduleId);
        if (schedule != null) _scheduleCache[trip.scheduleId] = schedule;
      }
      final schedule = _scheduleCache[trip.scheduleId];
      if (schedule == null) return null;

      // Fetch Route
      if (!_routeCache.containsKey(schedule.routeId)) {
        final route = await _firestoreService.getRoute(schedule.routeId);
        if (route != null) _routeCache[schedule.routeId] = route;
      }

      final route = _routeCache[schedule.routeId];
      if (route == null) return null;

      return EnrichedTrip(trip: trip, schedule: schedule, route: route);
    });
  }

  // Legacy stubs (Admin/Debug)
  Future<void> addTrip(Map<String, dynamic> data) async {
    await _firestoreService.addTrip(data);
  }

  Future<void> deleteTrip(String tripId) async {
    await _firestoreService.deleteTrip(tripId);
  }

  Future<void> updateTripDetails(
      String tripId, Map<String, dynamic> data) async {
    await _firestoreService.updateTripDetails(tripId, data);
  }

  // Ticket Verification
  Future<Ticket?> verifyTicket(String ticketId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('tickets')
          .doc(ticketId)
          .get();
      if (!snap.exists) return null;

      final data = snap.data()!;
      if (data['status'] == 'cancelled') return null;

      return Ticket.fromFirestore(snap);
    } catch (e) {
      debugPrint("Verify Error: $e");
      return null;
    }
  }

  Future<Ticket> getTicket(String ticketId) async {
    final snap = await FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .get();
    return Ticket.fromFirestore(snap);
  }

  // SMS
  Future<void> sendTicketSms(String ticketId) async {
    // Call Cloud Function or backend
    // Placeholder
    print("Sending SMS for ticket $ticketId");
  }

  Stream<List<Ticket>> getUserTickets() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestoreService.getUserTickets(uid);
  }

  // Favorites Route
  Future<void> toggleRouteFavorite(String from, String to,
      {String? operatorName, double? price}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.toggleRouteFavorite(uid, from, to,
        operatorName: operatorName, price: price);
  }

  Future<bool> isRouteFavorite(String from, String to) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    return await _firestoreService.isRouteFavorite(uid, from, to);
  }

  Stream<List<Map<String, dynamic>>> getUserFavoriteRoutes() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestoreService.getUserFavoriteRoutes(uid);
  }

  // Bulk Booking (Conductor/Admin)
  Future<void> createBulkPendingBookings(
      List<EnrichedTrip> trips, List<int> seatNumbers) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    // Extract raw trips
    final rawTrips = trips.map((e) => e.trip).toList();
    await _firestoreService.createBulkPendingBookings(
        rawTrips, seatNumbers, currentUser);
  }

  // --- ADMIN COMPATIBILITY ---
  // These wrappers support the existing AdminScreen without full refactor

  List<String> availableCities = [];

  Future<void> fetchAvailableCities() async {
    availableCities = await getAvailableCities();
    notifyListeners();
  }

  Future<void> updateTrip(String tripId, Map<String, dynamic> data) =>
      updateTripDetails(tripId, data);

  // Placeholder - Recurring route logic is moved to Schedules, but keeping stub for clean compilation of old screens
  Future<void> createRecurringRoute(dynamic routeData) async {
    debugPrint("Deprecated: separate route/schedule creation needed.");
  }

  // Helper for admin screen dropdowns
  List<RouteModel> availableRoutes = [];
  Future<void> fetchAvailableRoutes() async {
    // TODO: Implement generic route fetch if needed for AdminScreen
    // For now, no-op or simple fetch stub
  }

  // --- LEGACY STUBS for SeatSelectionScreen ---
  List<String> selectedSeats = [];
  bool isBulkBooking = false; // Toggle
  List<DateTime> bulkDates = []; // For bulk

  void toggleSeat(String seatId) {
    if (selectedSeats.contains(seatId)) {
      selectedSeats.remove(seatId);
    } else {
      selectedSeats.add(seatId);
    }
    notifyListeners();
  }

  void selectTrip(EnrichedTrip trip) {
    selectedTrip = trip;
    // In real app, load booked seats here
    notifyListeners();
  }

  double calculateBulkTotal(double price) {
    int multiplier =
        isBulkBooking && bulkDates.isNotEmpty ? bulkDates.length : 1;
    return price * selectedSeats.length * multiplier;
  }

  // Method to handle user-only arg from BulkConfirmation (if needed)
  Future<String> createPendingBookingFromState(User user) async {
    // uses internal selectedSeats and selectedTrip
    if (selectedTrip == null) throw Exception("No trip selected");
    return createPendingBooking(selectedTrip!, selectedSeats);
  }

  // --- AdminDashboard Compatibility ---
  // --- ADMIN USER MANAGEMENT ---
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return FirebaseFirestore.instance.collection('users').snapshots().map(
        (snap) => snap.docs.map((e) => {...e.data(), 'uid': e.id}).toList());
  }

  Future<void> updateUserProfile(String uid, String name, String role) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'displayName': name,
      'role': role,
    });
  }

  Future<void> registerUserAsAdmin({
    required String email,
    required String password,
    String? displayName,
    String role = 'customer',
  }) async {
    // This typically requires a Cloud Function to create a user with a specific role
    debugPrint("Registration from Admin panel stub: $email, $role");
  }

  Future<void> deleteUserProfile(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();
  }

  // --- MISSING METHODS RESTORATION ---

  User? get _currentUser => _auth.currentUser;

  int get seatsPerTrip => 40; // Default capacity

  void setDepartureDate(DateTime date) {
    tripDate = date;
    notifyListeners();
  }

  // Used by PaymentSuccessScreen
  Future<bool> confirmBooking(String bookingId,
      {String? paymentIntentId}) async {
    try {
      await _firestoreService.confirmBooking(bookingId,
          paymentIntentId: paymentIntentId);
      return true;
    } catch (e) {
      debugPrint("Booking confirmation failed: $e");
      return false;
    }
  }

  // Used by ConductorDashboard
  FirestoreService get service => _firestoreService;

  Future<void> updateTripStatusAsConductor(String tripId, TripStatus status,
      {int delayMinutes = 0}) async {
    await _firestoreService.updateStatus(tripId, status, delayMinutes);
  }

  Future<void> initializePersistence() async {
    // Stub for now, or implement cache init
    debugPrint("Persistence Initialized");
  }

  Stream<List<Trip>> getUserFavorites() {
    if (_currentUser == null) return Stream.value([]);
    // Using snapshots from user subcollection
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('favorites')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Trip.fromFirestore(d)).toList());
  }

  bool get isPreviewMode => false; // Stub

  Ticket? get currentTicket => _currentTicket;
  Ticket? _currentTicket; // Backing field

  Future<void> submitFeedback(
      dynamic rating, String comment, String userId) async {
    final tripId = selectedTrip?.trip.id ?? 'unknown_trip';
    await FirebaseFirestore.instance.collection('feedback').add({
      'tripId': tripId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- ADMIN ROUTE MANAGEMENT ---
  Future<void> saveRoute(dynamic routeData) async {
    if (routeData is RouteModel) {
      if (routeData.id.isEmpty) {
        await _firestoreService.addRoute(routeData);
      } else {
        await _firestoreService.updateRoute(routeData);
      }
    } else if (routeData is Map<String, dynamic>) {
      // Legacy Map support from AdminRouteScreen
      final newRoute = RouteModel(
        id: '',
        originCity: routeData['fromCity'] ?? '',
        destinationCity: routeData['toCity'] ?? '',
        stops: [],
        distanceKm: 0,
        estimatedDurationMins: 60, // Default
        isActive: true,
        via: routeData['via'] ?? '',
      );
      await _firestoreService.addRoute(newRoute);
    }
  }

  DateTime? get travelDate => tripDate;
  void setPreviewMode(bool value) {
    // Stub
  }
}
