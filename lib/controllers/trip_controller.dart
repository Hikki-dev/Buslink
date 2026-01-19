import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../models/schedule_model.dart';
import '../models/route_model.dart'; // Added
import '../models/trip_view_model.dart'; // EnrichedTrip
import '../services/firestore_service.dart';
import '../services/notification_service.dart' as import_notification_service;
import '../services/sms_service.dart'; // Re-added for Automated SMS
import 'package:intl/intl.dart';

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
      var trips = await _firestoreService.searchTrips(from, to, date);

      // FILTER: If searching for TODAY, hide buses that have already departed
      // (User request: "if time rn is 12 AM then all busses before that should not be shown")
      final now = DateTime.now();
      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        trips = trips.where((t) {
          // Keep if departure is in future OR if it's already active (boarding/departed/onWay)
          // because a user might want to track a bus they just missed or see if it's running late.
          // BUT User specifically said "before that should not be shown".
          // So let's align with "Scheduled time is in future" strict rule for new bookings.
          return t.departureDateTime.isAfter(now);
        }).toList();
      }

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

    // Notify Passengers (App Notification + SMS)
    try {
      final trip = await _firestoreService.getTrip(tripId);
      if (trip != null) {
        final routeName = "${trip.originCity} to ${trip.destinationCity}";

        // Map enum to string expected by Service
        String statusStr = 'unknown';
        if (status == TripStatus.delayed) statusStr = 'delayed';
        if (status == TripStatus.departed) statusStr = 'departed';
        if (status == TripStatus.arrived) statusStr = 'arrived';
        if (status == TripStatus.cancelled) statusStr = 'cancelled';
        if (status == TripStatus.onWay) statusStr = 'on way';

        // 1. In-App Notification
        await import_notification_service.NotificationService
            .notifyTripStatusChange(tripId, routeName, statusStr,
                delayMinutes: delayMinutes);

        // 2. Client-Side SMS
        // Fetch tickets to get phone numbers
        final ticketsSnap = await FirebaseFirestore.instance
            .collection('tickets')
            .where('tripId', isEqualTo: tripId)
            .where('status', isEqualTo: 'confirmed')
            .get();

        final List<String> phones = [];
        for (var doc in ticketsSnap.docs) {
          final data = doc.data();
          if (data['passengerPhone'] != null &&
              data['passengerPhone'].toString().isNotEmpty) {
            phones.add(data['passengerPhone'].toString());
          }
        }

        if (phones.isNotEmpty) {
          // Construct SMS Body

          // Trigger Batch SMS (Opens SMS App)
          // Create instance to avoid static if needed, or import static
          // We need to import sms_service.dart. I will assume it is available or add import.
          // SMS Removed per privacy requirements
          // await SmsService.sendBatchSMS(phones, smsBody);
        }
        if (phones.isNotEmpty) {
          // Trigger Automated SMS (Firestore Write)
          // "look your bus has arrived, bus got delayed by this many minutes or whatever"
          String extraMsg = "";
          if (delayMinutes > 0) extraMsg = "Delay: $delayMinutes mins.";

          await SmsService.sendTripStatusUpdate(phones, statusStr, extraMsg);
        }
      }
    } catch (e) {
      debugPrint("Error sending notification/SMS: $e");
    }
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
        enrichedTrip.trip, seatIds, currentUser,
        extraDetails: {
          'busNumber': enrichedTrip.busNumber,
          'operatorName': enrichedTrip.operatorName,
          'scheduleId': enrichedTrip.schedule.id,
        });
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
    debugPrint("Sending SMS for ticket $ticketId");
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
    try {
      availableCities = await getAvailableCities();
    } catch (e) {
      debugPrint("Error fetching cities (Quota/Network): $e");
      // Fallback or empty allowed
    }
    notifyListeners();
  }

  Future<void> updateTrip(String tripId, Map<String, dynamic> data) =>
      updateTripDetails(tripId, data);

  Future<void> createRecurringRoute(dynamic input) async {
    try {
      isLoading = true;
      notifyListeners();

      final tripData = input['data'] as Map<String, dynamic>;
      final days = input['days'] as List<int>;

      // 1. Ensure Route Exists
      String routeId = tripData['routeId'] ?? '';
      RouteModel? route;

      if (routeId.isNotEmpty) {
        route = await _firestoreService.getRoute(routeId);
      }

      if (route == null) {
        // Create new Route
        final newRoute = RouteModel(
          id: '',
          originCity: tripData['fromCity'],
          destinationCity: tripData['toCity'],
          stops: [],
          distanceKm: 0,
          estimatedDurationMins: _parseDuration(tripData['duration']),
          isActive: true,
          via: tripData['via'] ?? '',
        );
        final ref = await _firestoreService.addRoute(newRoute);
        routeId = ref.id;
        route = newRoute.copyWith(id: routeId);
      }

      // 2. Create Schedule
      final depDate = tripData['departureTime'] as DateTime;
      final depTimeStr =
          "${depDate.hour.toString().padLeft(2, '0')}:${depDate.minute.toString().padLeft(2, '0')}";

      final schedule = ScheduleModel(
        id: '', // Generated by Firestore
        routeId: routeId,
        busNumber: tripData['busNumber'] ?? 'Standard',
        operatorName: tripData['operatorName'] ?? 'BusLink',
        busType: 'Standard', // Default
        amenities: [],
        recurrenceDays: days,
        departureTime: depTimeStr,
        basePrice: (tripData['price'] as num).toDouble(),
        totalSeats: (tripData['totalSeats'] as num).toInt(),
      );

      final docRef = await _firestoreService.addSchedule(schedule);
      final savedSchedule = schedule.copyWith(id: docRef.id);

      // 3. Generate Trips
      await _firestoreService.generateTripsForSchedule(
          savedSchedule, route, 30); // Generate for 30 days
    } catch (e) {
      debugPrint("Error creating recurring route: $e");
      if (e is FormatException) {
        throw Exception("Invalid data format: Please check dates and numbers.");
      }
      throw Exception("Failed to generate trips: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int _parseDuration(String durationStr) {
    if (!durationStr.contains(':')) return 60;
    try {
      final parts = durationStr.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return (h * 60) + m;
    } catch (_) {
      return 60;
    }
  }

  // Helper for admin screen dropdowns
  List<RouteModel> availableRoutes = [];
  Future<void> fetchAvailableRoutes() async {
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
    if (selectedTrip?.trip.id != trip.trip.id) {
      selectedSeats.clear();
    }
    selectedTrip = trip;
    // In real app, load booked seats here
    notifyListeners();
  }

  double calculateBulkTotal(double price) {
    int multiplier =
        isBulkBooking && bulkDates.isNotEmpty ? bulkDates.length : 1;
    return price * selectedSeats.length * multiplier;
  }

  // Bulk Passenger Sync State
  int bulkPassengers = 1;
  void setBulkPassengers(int val) {
    bulkPassengers = val;
    notifyListeners();
  }

  // Method to handle user-only arg from BulkConfirmation (if needed)
  Future<String> createPendingBookingFromState(User user) async {
    if (selectedTrip == null) throw Exception("No trip selected");

    if (isBulkBooking && bulkDates.isNotEmpty) {
      final schedule = selectedTrip!.schedule;
      final route = selectedTrip!.route;

      // Extra details (Operator/Bus) are constant for the schedule
      final extraDetails = {
        'busNumber': selectedTrip!.busNumber,
        'operatorName': selectedTrip!.operatorName,
        'scheduleId': schedule.id,
      };

      // Parallel Processing for Performance
      final results = await Future.wait(bulkDates.map((date) async {
        try {
          // 1. Ensure Trip Exists
          final tripInstance =
              await _firestoreService.ensureTripExists(schedule, route, date);

          if (tripInstance != null) {
            // 2. Auto-Assign Seats (Real allocation)
            // Find available seats
            List<String> assignableSeats = [];
            int needed = selectedSeats.isNotEmpty
                ? selectedSeats.length
                // Fallback to bulkPassengers if selectedSeats is empty (e.g. from flow specific)
                // But usually selectedSeats is filled by "Auto-Assigned" logic in UI controller?
                // Actually selectedSeats might be "-1" placeholder or empty.
                // Let's rely on Quantity Dialog setting selectedSeats or just use numeric count.
                : bulkPassengers;

            // Strict Logic: If selectedSeats has concrete IDs, use them (unlikely for bulk recurring)
            // If selectedSeats has "-1" or is empty implying "Auto Selection", find seats.
            bool needsAutoAssign =
                selectedSeats.isEmpty || selectedSeats.contains("-1");

            if (needsAutoAssign) {
              final booked = tripInstance.bookedSeatNumbers.toSet();
              for (int i = 1; i <= schedule.totalSeats; i++) {
                if (assignableSeats.length >= needed) break;
                if (!booked.contains(i.toString())) {
                  assignableSeats.add(i.toString());
                }
              }

              if (assignableSeats.length < needed) {
                throw Exception(
                    "Not enough seats available on ${DateFormat('yyyy-MM-dd').format(date)}");
              }
            } else {
              // Validate specific seats (Only works if same seat map for all buses)
              for (var s in selectedSeats) {
                if (tripInstance.bookedSeatNumbers.contains(s)) {
                  throw Exception(
                      "Seat $s already booked on ${DateFormat('yyyy-MM-dd').format(date)}");
                }
              }
              assignableSeats = List.from(selectedSeats);
            }

            final id = await _firestoreService.createPendingBooking(
                tripInstance, assignableSeats, user,
                extraDetails: extraDetails);
            return id;
          } else {
            throw Exception(
                "No schedule available for ${DateFormat('yyyy-MM-dd').format(date)}");
          }
        } catch (e) {
          debugPrint("Bulk Booking Error date $date: $e");
          throw Exception(
              "Error on ${DateFormat('MMM d').format(date)}: ${e.toString().replaceAll('Exception:', '').trim()}");
        }
      }));

      if (results.isEmpty) {
        throw Exception("No valid trips found for selected dates.");
      }
      return results.join(',');
    } else {
      return createPendingBooking(selectedTrip!, selectedSeats);
    }
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
  // Used by PaymentSuccessScreen
  Future<bool> confirmBooking(String bookingId,
      {String? paymentIntentId}) async {
    // Handle Bulk (Comma Separated)
    if (bookingId.contains(',')) {
      final ids =
          bookingId.split(',').where((s) => s.trim().isNotEmpty).toList();
      try {
        final tickets = await _firestoreService.confirmBulkBookings(ids,
            paymentIntentId: paymentIntentId);

        // Notify (Aggregated)
        // Group by User and Trip
        final Map<String, List<Ticket>> userTickets = {};
        for (var t in tickets) {
          if (t.userId.isNotEmpty) {
            final key = "${t.userId}_${t.tripId}";
            userTickets.putIfAbsent(key, () => []).add(t);
          }
        }

        for (var key in userTickets.keys) {
          final bundle = userTickets[key]!;
          if (bundle.isEmpty) continue;
          final first = bundle.first;
          final userId = first.userId;
          final tripTitle =
              "${first.tripData['originCity']} to ${first.tripData['destinationCity']}";
          final seats = bundle.expand((t) => t.seatNumbers).join(', ');

          // Personalization
          String userName = "Passenger";
          if (first.passengerName.isNotEmpty) {
            userName = first.passengerName.split(' ').first;
          }

          // Fire and forget notification (Single Summary + Push)
          import_notification_service.NotificationService
              .sendNotificationToUser(
            userId: userId,
            title: "Booking Confirmed",
            body:
                "Great news $userName! Your trip ($tripTitle) is confirmed. Seats: $seats. Total: ${bundle.length} ticket(s).",
            type: "booking",
            relatedId: first.ticketId, // Link to first ticket or bundle?
          );

          // Immediate Local Notification (Reliability Fallback)
          await import_notification_service.NotificationService
              .showLocalNotification(
            id: first.ticketId.hashCode,
            title: "Booking Confirmed",
            body:
                "Great news $userName! Your trip ($tripTitle) is confirmed. Seats: $seats. Total: ${bundle.length} ticket(s).",
            payload: first.ticketId,
          );
        }
        return true;
      } catch (e) {
        debugPrint("Bulk booking confirmation failed: $e");
        return false;
      }
    }

    // Single Booking
    try {
      final ticket = await _firestoreService.confirmBooking(bookingId,
          paymentIntentId: paymentIntentId);

      // Notify User (Notification Center + Push)
      if (ticket.userId.isNotEmpty) {
        final tripTitle =
            "${ticket.tripData['originCity']} to ${ticket.tripData['destinationCity']}";

        // Personalization
        String userName = "Passenger";
        if (ticket.passengerName.isNotEmpty) {
          userName = ticket.passengerName.split(' ').first;
        }

        await import_notification_service.NotificationService
            .sendNotificationToUser(
          userId: ticket.userId,
          title: "Booking Confirmed",
          body:
              "Confirmed! $userName, your trip ($tripTitle) is all set. Seat(s): ${ticket.seatNumbers.join(', ')}",
          type: "booking",
          relatedId: ticket.ticketId,
        );

        // Immediate Local Notification (Reliability Fallback for User's own device)
        await import_notification_service.NotificationService
            .showLocalNotification(
          id: ticket.ticketId.hashCode,
          title: "Booking Confirmed",
          body:
              "Confirmed! $userName, your trip ($tripTitle) is all set. Seat(s): ${ticket.seatNumbers.join(', ')}",
          payload: ticket.ticketId,
        );

        // --- SCHEDULE LOCAL REMINDER ---
        // Parse Departure Time from tripData
        try {
          DateTime? departTime;
          final dRaw = ticket.tripData['departureTime'];
          if (dRaw is Timestamp) departTime = dRaw.toDate();
          if (dRaw is DateTime) departTime = dRaw;
          if (dRaw is String) departTime = DateTime.tryParse(dRaw);

          if (departTime != null) {
            // Schedule for 1 hour before
            final reminderTime = departTime.subtract(const Duration(hours: 1));
            // Create a unique ID from ticket hash
            final notifId = ticket.ticketId.hashCode;

            await import_notification_service.NotificationService
                .scheduleTripReminder(
                    notifId,
                    "Trip Reminder",
                    "Your bus to ${ticket.tripData['destinationCity']} leaves in 1 hour!",
                    reminderTime);
          }
        } catch (e) {
          debugPrint("Failed to schedule local reminder: $e");
        }
      }
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
    // Redirect to main updateStatus to trigger Notifications & SMS
    await updateStatus(tripId, status, delayMinutes);
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
  // --- NOTIFICATIONS ---
  Future<List<String>> getPassengerPhones(String tripId) async {
    return _firestoreService.getPassengerPhonesForTrip(tripId);
  }
}
