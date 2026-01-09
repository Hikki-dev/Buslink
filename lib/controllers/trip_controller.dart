// lib/controllers/trip_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../models/route_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class TripController extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final AuthService _authService = AuthService();

  FirestoreService get service => _service;

  void setConductorTrip(Trip trip) {
    conductorSelectedTrip = trip;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? fromCity;
  String? toCity;
  DateTime? travelDate;

  List<Trip> searchResults = [];
  List<Trip> allTripsForAdmin = [];
  List<String> availableCities = []; // Dynamic list
  List<RouteModel> availableRoutes = [];

  Future<void> fetchAvailableCities() async {
    try {
      availableCities = await _service.getAvailableCities();
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching cities: $e");
    }
  }

  Future<void> fetchAvailableRoutes() async {
    try {
      // Since getRoutesStream is a stream, we can't await it easily for a single fetch?
      // Actually service has getRoutesStream. Let's add a getRoutes Future in service or just consume stream.
      // We will listen to the stream in the UI usually, but for Dropdown logic a simple fetch or list cache is fine.
      // Let's assume we want a one-time fetch for the dropdown when opening the dialog.

      // We'll create a temporary logic to get cached routes from stream if we subscribed?
      // Or just fetch once. To avoid complexity, I'll add a getRoutes Future to logic.
      // But service only has getRoutesStream.
      // I'll add a simple getRoutes to service first or just use .first on stream.

      final snapshot = await _service.getRoutesStream().first;
      availableRoutes = snapshot;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching routes: $e");
    }
  }

  Trip? selectedTrip;
  List<int> selectedSeats = [];
  Ticket? currentTicket;

  bool isAdminMode = false;
  bool isPreviewMode = false; // For Admin "Preview App" banner persistence

  Future<void> initializePersistence() async {
    final prefs = await SharedPreferences.getInstance();
    isPreviewMode = prefs.getBool('admin_preview_mode') ?? false;
    notifyListeners();
  }

  Future<void> setPreviewMode(bool value) async {
    isPreviewMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('admin_preview_mode', value);
    notifyListeners();
  }

  Trip? conductorSelectedTrip;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // --- Round Trip State ---
  bool isRoundTrip = false;
  DateTime? returnDate;

  void setRoundTrip(bool enabled) {
    isRoundTrip = enabled;
    notifyListeners();
  }

  void setReturnDate(DateTime date) {
    returnDate = date;
    notifyListeners();
  }

  // --- Bulk Booking State ---
  bool isBulkBooking = false;
  List<DateTime> bulkDates = [];
  int seatsPerTrip = 1;
  List<List<Trip>> bulkSearchResults = []; // Matrix: [DayIndex][Trips]

  void setBulkMode(bool enabled) {
    isBulkBooking = enabled;
    if (enabled) {
      // Default to today and tomorrow if empty
      if (bulkDates.isEmpty) {
        final now = DateTime.now();
        bulkDates = [now, now.add(const Duration(days: 1))];
      }
    }
    notifyListeners();
  }

  void setBulkDates(List<DateTime> dates) {
    bulkDates = dates;
    // Sort dates
    bulkDates.sort();
    notifyListeners();
  }

  void setSeatsPerTrip(int seats) {
    seatsPerTrip = seats;
    notifyListeners();
  }

  void setDepartureDate(DateTime date) {
    travelDate = date;
    notifyListeners();
  }

  // --- ADDED: Bulk Total Calculation ---
  double calculateBulkTotal(double unitPrice) {
    if (!isBulkBooking || bulkDates.isEmpty) return unitPrice * seatsPerTrip;
    return unitPrice * seatsPerTrip * bulkDates.length;
  }

  Future<void> searchTrips(BuildContext context) async {
    if ((fromCity == null || fromCity!.isEmpty) &&
        (toCity == null || toCity!.isEmpty)) {
      // Empty Search: Show all trips for next 30 days
      _setLoading(true);
      try {
        final now = DateTime.now();
        searchResults = await _service.getTripsByDate(
            now, now.add(const Duration(days: 30)));
      } catch (e) {
        debugPrint("Error fetching all trips: $e");
        searchResults = [];
      }
      _setLoading(false);
      return;
    }

    if (bulkDates.isEmpty && travelDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a date")),
      );
      return;
    }
    _setLoading(true);

    try {
      if (isBulkBooking && bulkDates.isNotEmpty) {
        // --- BULK SEARCH LOGIC ---
        bulkSearchResults = [];

        // 1. Fetch trips for each date
        for (final date in bulkDates) {
          final tripsForDay = await _service.searchTrips(
            fromCity!,
            toCity!,
            date,
          );
          bulkSearchResults.add(tripsForDay);
        }

        if (bulkSearchResults.isEmpty) {
          searchResults = [];
          _setLoading(false);
          return;
        }

        // 2. Filter: Find "Series"
        // A series matches if a bus with same Number & Operator exists on ALL dates
        // AND has enough capacity (total - booked >= seatsPerTrip)
        // AND isn't cancelled.

        final day0Trips = bulkSearchResults[0];
        final List<Trip> validSeriesStarters = [];

        for (final startTrip in day0Trips) {
          // Check Day 0 capacity
          if ((startTrip.totalSeats - startTrip.bookedSeats.length) <
              seatsPerTrip) {
            continue;
          }

          bool isSeriesComplete = true;

          for (int i = 1; i < bulkSearchResults.length; i++) {
            final dayTrips = bulkSearchResults[i];

            // Find match
            final matchingTrip = dayTrips
                .where((t) =>
                    t.busNumber == startTrip.busNumber &&
                    t.operatorName == startTrip.operatorName)
                .firstOrNull;

            if (matchingTrip == null) {
              isSeriesComplete = false;
              break;
            }

            // Check capacity for matching trip
            if ((matchingTrip.totalSeats - matchingTrip.bookedSeats.length) <
                seatsPerTrip) {
              isSeriesComplete = false;
              break;
            }
          }

          if (isSeriesComplete) {
            validSeriesStarters.add(startTrip);
          }
        }
        searchResults = validSeriesStarters;
      } else {
        // --- STANDARD SEARCH ---
        // Ensure travelDate is set if not bulk
        travelDate ??= DateTime.now();
        debugPrint(
            "TripController: Searching trips from $fromCity to $toCity on $travelDate");
        searchResults = await _service.searchTrips(
          fromCity!,
          toCity!,
          travelDate!,
        );

        // Filter out past trips if searching for TODAY
        final now = DateTime.now();
        final isToday = travelDate!.year == now.year &&
            travelDate!.month == now.month &&
            travelDate!.day == now.day;

        if (isToday) {
          searchResults = searchResults.where((t) {
            return t.departureTime.isAfter(now);
          }).toList();
        }

        debugPrint("TripController: Found ${searchResults.length} trips.");
      }
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

  // --- ADDED: Load Conductor's Assigned Trips ---
  Future<List<Trip>> loadConductorTrips(String conductorId) async {
    try {
      return await _service.getTripsByConductor(conductorId);
    } catch (e) {
      debugPrint("Error loading conductor trips: $e");
      return [];
    }
  }

  // --- ADDED: Update Trip Status (Arrived, Departed, etc) ---
  Future<void> updateTripStatus(String tripId, TripStatus status) async {
    try {
      await _service.updateStatus(tripId, status, 0); // Delay 0 for now
      notifyListeners();
    } catch (e) {
      debugPrint("Error updating trip status: $e");
      rethrow;
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

  // --- ADDED: Create Recurring Route & Generate Trips ---
  Future<void> createRecurringRoute(
    BuildContext context,
    Map<String, dynamic> routeData,
    List<int> recurrenceDays, // [1, 2, ... 7] where 1 = Monday
  ) async {
    _setLoading(true);
    try {
      // 1. Save Route Definition
      // We assume departureTime/arrivalTime in routeData are NOT set (null),
      // or at least irrelevant. We rely on time components if passed, or we parse them?
      // Actually, AdminRouteScreen currently sends 'duration' (HH:MM) and 'departureTime' (null).
      // We need 'departureHour'/'departureMinute' which usually come from the TimePicker,
      // BUT AdminRouteScreen doesn't send those explicitly in the map anymore?
      // Wait, AdminRouteScreen sends:
      // duration: "HH:MM"
      // via, price, etc.
      // It DOES NOT send departureTime anymore.

      // We need to know specific Departure Time for the schedule.
      // AdminRouteScreen likely sends 'departureTime' as a DateTime object from the TimePicker
      // even if it removed the *field* from the map construction in _submit?
      // Let's check _submit in AdminRouteScreen later.
      // Assuming routeData['departureTime'] IS a DateTime representing the time of day.

      final DateTime dep =
          routeData['departureTime']; // This holds the TiimeOfDay date

      // Parse Duration String "HH:MM" robustly
      final durationStr = routeData['duration'] as String;
      int durH = 0;
      int durM = 0;
      if (durationStr.contains(':')) {
        final parts = durationStr.split(':');
        durH = int.tryParse(parts[0]) ?? 0;
        durM = int.tryParse(parts[1]) ?? 0;
      }
      final duration = Duration(hours: durH, minutes: durM);

      // Determine Arrival Time relative to Departure
      // Just for route definition metadata
      final DateTime arr = dep.add(duration);

      final Map<String, dynamic> routeStorageData = {
        ...routeData,
        'departureTime': null,
        'arrivalTime': null,
        'departureHour': dep.hour,
        'departureMinute': dep.minute,
        'arrivalHour': arr.hour,
        'arrivalMinute': arr.minute,
        'recurrenceDays': recurrenceDays,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Convert to RouteModel before adding
      final tempRoute = RouteModel.fromMap(routeStorageData, '');
      final DocumentReference routeRef = await _service.addRoute(tempRoute);
      debugPrint("Route created with ID: ${routeRef.id}");

      // 2. Generate Trips for next 60 days (2 Months)
      const int daysToGenerate = 60;
      final DateTime now = DateTime.now();

      final WriteBatch batch = FirebaseFirestore.instance.batch();
      int tripCount = 0;

      for (int i = 0; i < daysToGenerate; i++) {
        // Check if date is in the past (before Today at 00:00) to ensure we don't skip today if it's "late" but trip hasn't happened?
        // Actually, just generate for dates >= TODAY.
        final DateTime targetDate = now.add(Duration(days: i));

        if (recurrenceDays.contains(targetDate.weekday)) {
          // Construct specific Departure Time
          final DateTime tripDeparture = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            dep.hour,
            dep.minute,
          );

          final DateTime tripArrival = tripDeparture.add(duration);

          final DocumentReference newTripRef =
              FirebaseFirestore.instance.collection('trips').doc();

          final Map<String, dynamic> tripMap = {
            'operatorName': routeData['operatorName'],
            'busNumber': routeData['busNumber'],
            'fromCity': routeData['fromCity'],
            'toCity': routeData['toCity'],
            'departureTime': Timestamp.fromDate(tripDeparture),
            'arrivalTime': Timestamp.fromDate(tripArrival),
            'price': routeData['price'],
            'totalSeats': routeData['totalSeats'],
            'platformNumber': routeData['platformNumber'],
            'status': 'onTime',
            'delayMinutes': 0,
            'bookedSeats': [],
            'stops': routeData['stops'] ?? [],
            'via': routeData['via'] ?? '',
            'duration': routeData['duration'] ?? '',
            'operatingDays': recurrenceDays,
            'isGenerated': true,
            'routeId': routeRef.id,
            'blockedSeats': routeData['blockedSeats'] ?? [],
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
        SnackBar(content: Text("Route & $tripCount trips created (60 Days)!")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("ERROR in createRecurringRoute: $e");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding route: $e")),
      );
    }
    _setLoading(false);
  }

  Future<void> saveRoute(Map<String, dynamic> routeData) async {
    try {
      await _service.addRoute(RouteModel.fromMap(routeData, ''));
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving route: $e");
      rethrow;
    }
  }

  // --- ADDED: Update Trip ---
  Future<void> updateTrip(
      BuildContext context, String tripId, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      // Ensure timestamps if passed as DateTime
      if (data['departureTime'] is DateTime) {
        data['departureTime'] = Timestamp.fromDate(data['departureTime']);
      }
      if (data['arrivalTime'] is DateTime) {
        data['arrivalTime'] = Timestamp.fromDate(data['arrivalTime']);
      }

      await _service.updateTripDetails(tripId, data);

      // Update local list
      final index = searchResults.indexWhere((t) => t.id == tripId);
      if (index != -1) {
        // We might want to reload search here, but for now let's just assume success
        // or re-fetch logic could be better.
        // Simple hack: reload current search result if possible
        // For now, just notify.
      }
      notifyListeners();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip updated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating trip: $e")),
        );
      }
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

  // --- 8. Persistent Booking Flow (Stripe Redirect) ---
  Future<String?> createPendingBooking(User user) async {
    if (selectedTrip == null || selectedSeats.isEmpty) return null;
    _setLoading(true);
    try {
      // --- TIME LIMIT CHECK (Only check Day 0 for simplicity, or all?) ---
      // For bulk, Day 0 is closest.
      final trip = selectedTrip!;
      final timeDifference = trip.departureTime.difference(DateTime.now());

      if (timeDifference.inHours < 2) {
        final userDoc = await _service.getUserData(user.uid);
        final role =
            (userDoc.data() as Map<String, dynamic>?)?['role'] ?? 'customer';

        if (role != 'conductor' && role != 'admin') {
          throw Exception("Booking closes 2 hours before departure.");
        }
      }

      if (isBulkBooking && bulkDates.length > 1) {
        // --- BULK CREATION ---
        final List<Trip> tripsToBook = [];

        // Find matching trips in bulkSearchResults
        // day0 is selectedTrip.
        tripsToBook.add(selectedTrip!);

        for (int i = 1; i < bulkSearchResults.length; i++) {
          final dayTrips = bulkSearchResults[i];
          final match = dayTrips
              .where((t) =>
                  t.busNumber == selectedTrip!.busNumber &&
                  t.operatorName == selectedTrip!.operatorName)
              .firstOrNull;

          if (match != null) {
            tripsToBook.add(match);
          }
        }

        // Call service to batch create
        final List<String> bookingIds = await _service
            .createBulkPendingBookings(tripsToBook, selectedSeats, user);

        return bookingIds.join(","); // Return comma separated IDs
      } else {
        // --- SINGLE CREATION ---
        final bookingId = await _service.createPendingBooking(
            selectedTrip!, selectedSeats, user);
        return bookingId;
      }
    } catch (e) {
      debugPrint("Error creating pending booking: $e");
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- Booking Confirmation ---
  List<Ticket> confirmedTickets = [];

  Future<bool> confirmBooking(String bookingId) async {
    _setLoading(true);
    confirmedTickets = []; // Clear previous
    try {
      if (bookingId.contains(',')) {
        // Bulk Confirmation
        final ids = bookingId.split(',');
        for (final id in ids) {
          final ticket = await _service.confirmBooking(id.trim());
          confirmedTickets.add(ticket);
        }
        currentTicket = confirmedTickets.first; // For backward compatibility

        // Refresh Trip Data (for the first on, or all? Ideally all involved trips)
        // For simplicity, refresh selectedTrip
        final trip = await _service.getTrip(currentTicket!.tripId);
        if (trip != null) {
          selectedTrip = trip;
        }
        notifyListeners();
        _setLoading(false);
        return true;
      } else {
        // Single Confirmation
        final ticket = await _service.confirmBooking(bookingId);
        currentTicket = ticket;
        confirmedTickets.add(ticket);

        final trip = await _service.getTrip(ticket.tripId);
        if (trip != null) {
          selectedTrip = trip;
        }
        notifyListeners();
        _setLoading(false);
        return true;
      }
    } catch (e) {
      debugPrint('Error confirming booking: $e');
      _setLoading(false);
      return false;
    }
  }

  // Legacy (Direct) Method - Keeping for reference or fallback
  Future<bool> processBooking(BuildContext context, User user) async {
    if (selectedTrip == null || selectedSeats.isEmpty) return false;

    _setLoading(true);
    try {
      // Simple direct booking
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
      ).showSnackBar(SnackBar(content: Text("Booking Error: ${e.toString()}")));
      _setLoading(false);
      return false;
    }
  }

  // --- ADDED: Offline Booking Wrapper ---
  Future<bool> createOfflineBooking(
      BuildContext context, String passengerName, User conductor) async {
    if (selectedTrip == null || selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Select a trip and at least one seat.")));
      return false;
    }

    _setLoading(true);
    try {
      currentTicket = await _service.createOfflineBooking(
          selectedTrip!, selectedSeats, passengerName, conductor);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Offline Booking Failed: ${e.toString()}")),
        );
      }
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

  Future<void> removeFavorite(String userId, String tripId) async {
    await _service.removeFavorite(userId, tripId);
    notifyListeners();
  }

  Future<bool> isTripFavorite(String userId, String tripId) {
    return _service.isTripFavorite(userId, tripId);
  }

  Stream<List<Map<String, dynamic>>> getUserFavorites(String userId) {
    return _service.getUserFavoriteRoutes(userId);
  }

  // Route Favorites
  Future<void> toggleRouteFavorite(
      String userId, String fromCity, String toCity,
      {String? operatorName, double? price}) async {
    await _service.toggleRouteFavorite(userId, fromCity, toCity,
        operatorName: operatorName, price: price);
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
    // OPTIMISTIC UPDATE: Update UI immediately
    final oldStatus = conductorSelectedTrip?.status;
    final oldDelay = conductorSelectedTrip?.delayMinutes;

    // FSM VALIDATION
    if (oldStatus == TripStatus.completed && status == TripStatus.inProgress) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot resume a completed trip.")),
        );
      }
      return;
    }

    conductorSelectedTrip?.status = status;
    conductorSelectedTrip?.delayMinutes = delay;
    notifyListeners();

    try {
      // 1. Audit Log
      await _service.logTripStateChange(
        tripId: trip.id,
        oldState: oldStatus?.name ?? 'unknown',
        newState: status.name,
        changedBy:
            FirebaseAuth.instance.currentUser?.uid ?? 'unknown_conductor',
        location: await _getCurrentLocationData(),
        reason: 'Manual update by conductor',
      );

      // 2. Real-time Update (High Freq Collection)
      await _service.updateTripRealtimeStatus(trip.id, {
        'status': status.name,
        'delayMinutes': delay,
        'anomalyDetected': false, // Reset on manual override
      });

      // 3. Legacy Update (Main Doc)
      if (trip.id != "static_trip_id") {
        await _service.updateStatus(trip.id, status, delay);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to ${status.name.toUpperCase()}"),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on failure
      conductorSelectedTrip?.status = oldStatus ?? TripStatus.scheduled;
      conductorSelectedTrip?.delayMinutes = oldDelay ?? 0;
      notifyListeners();

      debugPrint("Trip Update Failed: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status (Offline?): $e")),
        );
      }
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
    if (fromCity == city) return;
    fromCity = city;
    notifyListeners();
  }

  void setToCity(String? city) {
    if (toCity == city) return;
    toCity = city;
    notifyListeners();
  }

  void setDate(DateTime? date) {
    if (travelDate == date) return;
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

  Future<Ticket?> getTicketById(String ticketId) async {
    return await _service.getTicket(ticketId);
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _service.updateUserRole(uid, newRole);
    notifyListeners();
  }

  Future<void> updateUserProfile(String uid, String name, String role) async {
    await _service.updateUserProfile(uid, {
      'displayName': name,
      'role': role,
    });
    notifyListeners();
  }

  Future<void> createUserProfile(Map<String, dynamic> userData) async {
    await _service.createUserProfile(userData);
    notifyListeners();
  }

  Future<void> deleteUserProfile(String uid) async {
    await _service.deleteUserProfile(uid);
    notifyListeners();
  }

  Future<void> registerUserAsAdmin({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    _setLoading(true);
    try {
      await _authService.registerUserAsAdmin(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      // We don't need to manually refresh users as the stream will pick it up
      // provided the document was created.
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitFeedback(int rating, String comment, String userId) async {
    await _service.submitFeedback({
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<Ticket?> verifyTicket(String ticketId) async {
    _setLoading(true);
    try {
      final ticket = await _service.verifyTicket(ticketId);
      _setLoading(false);
      return ticket;
    } catch (e) {
      debugPrint("Verify Error: $e");
      _setLoading(false);
      return null;
    }
  }

  Future<Map<String, dynamic>> _getCurrentLocationData() async {
    try {
      // Check permissions first to avoid errors
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'error': 'Location permission denied'};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {'error': 'Location permission denied forever'};
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      debugPrint("Error getting location for log: $e");
      return {'error': e.toString()};
    }
  }
}
