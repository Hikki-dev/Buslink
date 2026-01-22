// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart'; // Added ScheduleModel

import 'dart:math';
import 'cache_service.dart';

class FirestoreService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  final String tripCollection = 'trips';
  final String ticketCollection = 'tickets';
  final String userCollection = 'users';
  final String routeCollection = 'routes';
  final String scheduleCollection = 'schedules'; // New Collection

  String _generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<DocumentSnapshot> getUserData(String uid) {
    return _db.collection(userCollection).doc(uid).get();
  }

  // --- PHASE 1 & 2 REFACTOR: Routes ---

  Stream<List<RouteModel>> getRoutesStream() {
    return _db.collection(routeCollection).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => RouteModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<DocumentReference> addRoute(RouteModel route) {
    return _db.collection(routeCollection).add(route.toJson());
  }

  Future<void> updateRoute(RouteModel route) async {
    await _db.collection(routeCollection).doc(route.id).update(route.toJson());
  }

  Future<void> deleteRoute(String routeId) async {
    await _db.collection(routeCollection).doc(routeId).delete();
  }

  Future<RouteModel?> getRoute(String routeId) async {
    final doc = await _db.collection(routeCollection).doc(routeId).get();
    if (doc.exists) return RouteModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  // --- PHASE 2 REFACTOR: Schedules ---

  Stream<List<ScheduleModel>> getSchedulesStream() {
    return _db.collection(scheduleCollection).snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => ScheduleModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<DocumentReference> addSchedule(ScheduleModel schedule) {
    return _db.collection(scheduleCollection).add(schedule.toJson());
  }

  Future<void> updateSchedule(ScheduleModel schedule) async {
    await _db
        .collection(scheduleCollection)
        .doc(schedule.id)
        .update(schedule.toJson());
  }

  Future<void> deleteSchedule(String scheduleId) async {
    await _db.collection(scheduleCollection).doc(scheduleId).delete();
  }

  // --- PHASE 2: Trip Generation Logic ---

  /// Generates trips for a given Schedule for [daysAhead] days from now.
  /// Skips dates that don't match recurrenceDays.
  /// Checks for existing trips to avoid duplicates (safeguard).
  Future<int> generateTripsForSchedule(
      ScheduleModel schedule, RouteModel route, int daysAhead) async {
    int createdCount = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final batch = _db.batch();

    // Parse departure time HH:mm
    int depHour = 0;
    int depMinute = 0;
    try {
      final parts = schedule.departureTime.trim().split(':');
      depHour = int.parse(parts[0]);
      depMinute = int.parse(parts[1]);
    } catch (e) {
      debugPrint("Error parsing schedule time '${schedule.departureTime}': $e");
      return 0; // Abort if time is invalid
    }

    for (int i = 0; i < daysAhead; i++) {
      final targetDate = today.add(Duration(days: i));
      if (!schedule.recurrenceDays.contains(targetDate.weekday)) {
        continue;
      }

      // Check existence (basic check: same schedule, same date)
      // Note: For high volume, this might be slow. Optimization: Batch Read.
      final dayStart =
          DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
      final dayEnd = DateTime(
          targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

      final existingQuery = await _db
          .collection(tripCollection)
          .where('scheduleId', isEqualTo: schedule.id)
          .get();

      // Filter in memory to avoid composite index error
      final existing = existingQuery.docs.where((doc) {
        final data = doc.data();
        if (data['departureDateTime'] == null) return false;
        final dt = (data['departureDateTime'] as Timestamp).toDate();
        return dt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
            dt.isBefore(dayEnd.add(const Duration(seconds: 1)));
      }).toList();

      if (existing.isNotEmpty) {
        continue; // Already exists
      }

      // Calculate Dates
      final departureDateTime = DateTime(targetDate.year, targetDate.month,
          targetDate.day, depHour, depMinute);
      final arrivalDateTime =
          departureDateTime.add(Duration(minutes: route.estimatedDurationMins));

      // Create Trip
      final docRef = _db.collection(tripCollection).doc();
      final newTrip = Trip(
        id: docRef.id,
        scheduleId: schedule.id,
        date: targetDate,
        originCity: route.originCity,
        destinationCity: route.destinationCity,
        departureDateTime: departureDateTime,
        arrivalDateTime: arrivalDateTime,
        price: schedule.basePrice,
        status: TripStatus.scheduled.name,
        bookedSeatNumbers: [], // New list for bookings
      );

      // Inject extra fields for UI compat if needed (Ticket metadata usually)
      final tripMap = newTrip.toJson();
      // Add denormalized fields for simple UI usage if strictly necessary,
      // but keeping clean for now as per "Do not hallucinate".

      batch.set(docRef, tripMap);
      createdCount++;
    }

    if (createdCount > 0) {
      await batch.commit();
    }
    return createdCount;
  }

  /// Ensures a trip exists for a specific date, creating it if necessary.
  Future<Trip?> ensureTripExists(
      ScheduleModel schedule, RouteModel route, DateTime date) async {
    // 1. Check if exists
    final existing = await getTripByScheduleAndDate(schedule.id, date);
    if (existing != null) return existing;

    // 2. Check validity (Recurrence)
    if (!schedule.recurrenceDays.contains(date.weekday)) {
      return null; // Not scheduled for this day
    }

    // 3. Create
    final docRef = _db.collection(tripCollection).doc();

    // Parse time
    int depHour = 0;
    int depMinute = 0;
    try {
      final parts = schedule.departureTime.trim().split(':');
      depHour = int.parse(parts[0]);
      depMinute = int.parse(parts[1]);
    } catch (_) {}

    final departureDateTime =
        DateTime(date.year, date.month, date.day, depHour, depMinute);
    final arrivalDateTime =
        departureDateTime.add(Duration(minutes: route.estimatedDurationMins));

    final newTrip = Trip(
      id: docRef.id,
      scheduleId: schedule.id,
      date: date,
      originCity: route.originCity,
      destinationCity: route.destinationCity,
      departureDateTime: departureDateTime,
      arrivalDateTime: arrivalDateTime,
      price: schedule.basePrice,
      status: TripStatus.scheduled.name,
      bookedSeatNumbers: [],
    );

    await docRef.set(newTrip.toJson());
    return newTrip;
  }

  // --- TRIPS (Read/Write) ---

  // Replaces searchTrips with correct query
  Future<List<Trip>> searchTrips(
    String origin,
    String destination,
    DateTime date,
  ) async {
    final DateTime dayStart = DateTime(date.year, date.month, date.day);
    final DateTime dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59);

    final String safeOrigin = origin.isEmpty
        ? ""
        : origin[0].toUpperCase() + origin.substring(1).toLowerCase();
    final String safeDest = destination.isEmpty
        ? ""
        : destination[0].toUpperCase() + destination.substring(1).toLowerCase();

    final snapshot = await _db
        .collection(tripCollection)
        // Note: Composite index required for originCity + destinationCity + departureDateTime
        .where('originCity', isEqualTo: safeOrigin)
        .where('destinationCity', isEqualTo: safeDest)
        .where('departureDateTime', isGreaterThanOrEqualTo: dayStart)
        .where('departureDateTime', isLessThanOrEqualTo: dayEnd)
        .get();

    if (snapshot.docs.isEmpty) return [];

    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  // Legacy getTripsByDate adjusted
  Future<List<Trip>> getTripsByDate(DateTime start, DateTime end) async {
    final snapshot = await _db
        .collection(tripCollection)
        .where('departureDateTime', isGreaterThanOrEqualTo: start)
        .where('departureDateTime', isLessThanOrEqualTo: end)
        .orderBy('departureDateTime')
        .get();

    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  Future<Trip?> getTrip(String tripId) async {
    final doc = await _db.collection(tripCollection).doc(tripId).get();
    if (doc.exists) {
      return Trip.fromFirestore(doc);
    }
    return null;
  }

  Stream<Trip> getTripStream(String tripId) {
    return _db.collection(tripCollection).doc(tripId).snapshots().map((doc) {
      return Trip.fromFirestore(doc);
    });
  }

  Future<Trip?> getTripByScheduleAndDate(
      String scheduleId, DateTime date) async {
    final DateTime dayStart = DateTime(date.year, date.month, date.day);
    final DateTime dayEnd =
        DateTime(date.year, date.month, date.day, 23, 59, 59);

    final snapshot = await _db
        .collection(tripCollection)
        .where('scheduleId', isEqualTo: scheduleId)
        .get();

    // Filter in memory to avoid composite index
    final docs = snapshot.docs.where((doc) {
      final data = doc.data();
      if (data['departureDateTime'] == null) return false;
      final dt = (data['departureDateTime'] as Timestamp).toDate();
      return dt.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          dt.isBefore(dayEnd.add(const Duration(seconds: 1)));
    }).toList();

    if (docs.isEmpty) return null;
    return Trip.fromFirestore(docs.first);
  }

  // Method to join Schedule data (Optimization: Client side join or Cloud Function preferable)
  // For now, client side helper
  Future<ScheduleModel?> getScheduleForTrip(String scheduleId) async {
    final doc = await _db.collection(scheduleCollection).doc(scheduleId).get();
    if (doc.exists) return ScheduleModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  // --- BOOKING (Updated for new Schema) ---

  Future<Ticket> processBooking(
      Trip trip,
      List<String> seatIds, // Changed to List<String> to match new Seat Schema
      User user,
      Map<String, dynamic>
          extraTripDetails // Passed from UI (merged Trip+Schedule)
      ) async {
    // 1. Fetch User Data from Firestore (Primary Source for Profile)
    Map<String, dynamic> userData = {};
    try {
      final userDoc = await _db.collection(userCollection).doc(user.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data()!;
      }
    } catch (e) {
      debugPrint("Warning: Could not fetch user profile for booking: $e");
    }

    // 2. Resolve Contact Info (Firestore > Auth > Guest)
    final String pName = userData['displayName'] ??
        userData['name'] ??
        user.displayName ??
        'Guest';
    final String pEmail = userData['email'] ?? user.email ?? '';
    final String pPhone = userData['phoneNumber'] ??
        userData['phone'] ??
        user.phoneNumber ??
        'N/A';

    final ticketRef = _db.collection(ticketCollection).doc();
    final tripRef = _db.collection(tripCollection).doc(trip.id);

    // Fetch FCM Token - Critical for Conductor Notifications
    String? fcmToken = userData['fcmToken'];

    await _db.runTransaction((transaction) async {
      DocumentSnapshot freshTripSnap = await transaction.get(tripRef);
      if (!freshTripSnap.exists) {
        throw Exception("Trip does not exist!");
      }
      Trip freshTrip = Trip.fromFirestore(freshTripSnap);

      for (String seat in seatIds) {
        if (freshTrip.bookedSeatNumbers.contains(seat)) {
          throw Exception('Seat $seat is already booked.');
        }
      }

      transaction.update(tripRef, {
        'bookedSeatNumbers': FieldValue.arrayUnion(seatIds),
      });
    });

    final newTicket = Ticket(
      ticketId: ticketRef.id,
      tripId: trip.id,
      userId: user.uid,
      seatNumbers: seatIds.map((e) => int.tryParse(e) ?? 0).toList(),
      passengerName: pName,
      passengerPhone: pPhone,
      passengerEmail: pEmail,
      bookingTime: DateTime.now(),
      totalAmount: trip.price * seatIds.length,
      tripData: extraTripDetails,
      shortId: _generateShortId(),
      fcmToken: fcmToken,
    );

    // Save with metadata for Search
    final ticketMap = newTicket.toJson();
    ticketMap['userData'] = {
      'name': pName,
      'email': pEmail,
      'phone': pPhone,
    };

    await ticketRef.set(ticketMap);
    return newTicket;
  }

  // --- REMAINING METHODS (Legacy Support or Refactoring) ---

  // NOTE: Many legacy methods (getAvailableCities, etc.) rely on old fields.
  // I will update getAvailableCities to check 'originCity' instead of 'fromCity'.

  List<String>? _cachedCities;
  Future<List<String>> getAvailableCities({bool forceRefresh = false}) async {
    if (_cachedCities != null && !forceRefresh) return _cachedCities!;

    if (!forceRefresh) {
      final persistentCache = CacheService().getCachedCities();
      if (persistentCache != null && persistentCache.isNotEmpty) {
        _cachedCities = persistentCache;
        return persistentCache;
      }
    }

    try {
      final routeSnap = await _db.collection(routeCollection).get();
      final Set<String> cities = {};

      if (routeSnap.docs.isNotEmpty) {
        for (var doc in routeSnap.docs) {
          final data = doc.data();
          // New Schema Keys with Fallback
          var origin = data['originCity'] ?? data['fromCity'];
          var dest = data['destinationCity'] ?? data['toCity'];

          if (origin != null) cities.add(origin.toString());
          if (dest != null) cities.add(dest.toString());
        }
      }

      if (cities.isEmpty) return [];
      final result = cities.toList()..sort();
      _cachedCities = result;
      CacheService().saveCities(result);
      return result;
    } catch (e) {
      debugPrint("Info: Using Fallback cities due to DB Error/Limit: $e");
      // Fallback to keep UI working
      return ["Colombo", "Kandy", "Galle", "Jaffna", "Matara", "Kurunegala"];
    }
  }

  // ... (Keeping generic User Management methods as is) ...

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await updateUserProfile(uid, {'role': newRole});
  }

  Future<void> createUserProfile(Map<String, dynamic> userData) {
    return _db.collection('users').doc(userData['uid']).set(userData);
  }

  Future<void> deleteUserProfile(String uid) {
    return _db.collection('users').doc(uid).delete();
  }

  // --- NOTIFICATION PREFERENCES ---
  Future<Map<String, dynamic>?> getNotificationPreferences(String uid) async {
    final doc = await _db.collection(userCollection).doc(uid).get();
    if (doc.exists && doc.data()!.containsKey('notificationPreferences')) {
      return doc.data()!['notificationPreferences'] as Map<String, dynamic>;
    }
    return null; // Return null implies defaults
  }

  Future<void> updateNotificationPreferences(
      String uid, Map<String, dynamic> prefs) async {
    await _db
        .collection(userCollection)
        .doc(uid)
        .update({'notificationPreferences': prefs});
  }

  // --- MISSING METHODS RESTORED & REFACTORED ---

  Future<List<Trip>> getTripsByConductor(String conductorId) async {
    // Queries Trips directly using the new conductorId field
    final tripSnaps = await _db
        .collection(tripCollection)
        .where('conductorId', isEqualTo: conductorId)
        .orderBy('departureDateTime', descending: true)
        .get();

    return tripSnaps.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  Future<void> updateStatus(
      String tripId, TripStatus status, int delayMinutes) async {
    await _db.collection(tripCollection).doc(tripId).update({
      'status': status.name,
      'delayMinutes': delayMinutes, // Note: TripModel needs this field if used
    });
  }

  Future<void> addTrip(Map<String, dynamic> tripData) async {
    await _db.collection(tripCollection).add(tripData);
  }

  Future<void> updateTripDetails(
      String tripId, Map<String, dynamic> data) async {
    await _db.collection(tripCollection).doc(tripId).update(data);
  }

  Future<void> deleteTrip(String tripId) async {
    await _db.collection(tripCollection).doc(tripId).delete();
  }

  // --- BOOKING ADVANCED ---

  Future<String> createPendingBooking(
      Trip trip, List<String> seatIds, User user,
      {Map<String, dynamic>? extraDetails}) async {
    // 1. Fetch User Data from Firestore
    Map<String, dynamic> userData = {};
    try {
      final userDoc = await _db.collection(userCollection).doc(user.uid).get();
      if (userDoc.exists) {
        userData = userDoc.data()!;
      }
    } catch (e) {
      debugPrint(
          "Warning: Could not fetch user profile for pending booking: $e");
    }

    // 2. Resolve Contact Info
    final String pName = userData['displayName'] ??
        userData['name'] ??
        user.displayName ??
        'Guest';
    final String pEmail = userData['email'] ?? user.email ?? '';
    final String pPhone = userData['phoneNumber'] ??
        userData['phone'] ??
        user.phoneNumber ??
        'N/A';

    final ticketRef = _db.collection(ticketCollection).doc();

    final Map<String, dynamic> tripDataSnapshot = trip.toJson();
    if (extraDetails != null) {
      tripDataSnapshot.addAll(extraDetails);
    }

    final ticket = Ticket(
        ticketId: ticketRef.id,
        tripId: trip.id,
        userId: user.uid,
        seatNumbers: seatIds.map((e) => int.tryParse(e) ?? 0).toList(),
        passengerName: pName,
        passengerPhone: pPhone,
        passengerEmail: pEmail,
        bookingTime: DateTime.now(),
        totalAmount: trip.price * seatIds.length,
        tripData: tripDataSnapshot,
        status: 'pending',
        shortId: _generateShortId());

    final tripRef = _db.collection(tripCollection).doc(trip.id);

    // Use Transaction to block seats ATOMICALLY
    await _db.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(tripRef);

      if (!snapshot.exists) {
        throw Exception("Trip does not exist!");
      }

      // Re-check availability within transaction
      List<dynamic> currentBooked = snapshot.get('bookedSeatNumbers') ?? [];

      for (String seatId in seatIds) {
        if (currentBooked.contains(seatId)) {
          throw Exception(
              "Seat $seatId is already booked! Please select another.");
        }
      }

      // Add to booked list
      transaction.update(tripRef, {
        'bookedSeatNumbers': FieldValue.arrayUnion(seatIds),
      });

      // Writes must come after reads
      final finalTicketMap = ticket.toJson();
      finalTicketMap['userData'] = {
        'name': pName,
        'email': pEmail,
        'phone': pPhone,
      };
      transaction.set(ticketRef, finalTicketMap);
    });

    return ticketRef.id;
  }

  Future<List<String>> createBulkPendingBookings(
      List<Trip> trips, List<int> seatNumbers, User user) async {
    List<String> seatIds = seatNumbers.map((e) => e.toString()).toList();
    List<String> ids = [];
    final batchId = "BATCH_${DateTime.now().millisecondsSinceEpoch}";

    for (var trip in trips) {
      // Pass batchId in extraDetails so it persists in tripData
      ids.add(await createPendingBooking(trip, seatIds, user, extraDetails: {
        'batchId': batchId,
      }));
    }
    return ids;
  }

  Future<Ticket> confirmBooking(String bookingId,
      {String? paymentIntentId}) async {
    final ticketRef = _db.collection(ticketCollection).doc(bookingId);

    final updateData = {'status': 'confirmed'};
    if (paymentIntentId != null) {
      updateData['paymentIntentId'] = paymentIntentId;
    }

    await ticketRef.update(updateData);

    final snap = await ticketRef.get();
    return Ticket.fromFirestore(snap);
  }

  Future<List<Ticket>> confirmBulkBookings(List<String> bookingIds,
      {String? paymentIntentId}) async {
    final batch = _db.batch();
    final updateData = {'status': 'confirmed'};
    if (paymentIntentId != null) {
      updateData['paymentIntentId'] = paymentIntentId;
    }

    for (var id in bookingIds) {
      final ref = _db.collection(ticketCollection).doc(id);
      batch.update(ref, updateData);
    }

    await batch.commit();

    // Fetch updated tickets to return
    // Note: Can't easily batch get, so loop get or whereIn (limit 10)
    // For now, loop get is fine for reasonable bulk size (e.g. 5-30)
    List<Ticket> confirmedTickets = [];
    for (var id in bookingIds) {
      final snap = await _db.collection(ticketCollection).doc(id).get();
      if (snap.exists) {
        confirmedTickets.add(Ticket.fromFirestore(snap));
      }
    }
    return confirmedTickets;
  }

  Future<Ticket> createOfflineBooking(
      Trip trip, List<int> seatNumbers, String passengerName, User conductor,
      {String? phoneNumber}) async {
    List<String> seatIds = seatNumbers.map((e) => e.toString()).toList();
    final ticketRef = _db.collection(ticketCollection).doc();

    final tripRef = _db.collection(tripCollection).doc(trip.id);
    await tripRef.update({
      'bookedSeatNumbers': FieldValue.arrayUnion(seatIds),
    });

    final ticket = Ticket(
        ticketId: ticketRef.id,
        tripId: trip.id,
        userId: conductor.uid,
        seatNumbers: seatNumbers,
        passengerName: passengerName,
        passengerPhone: phoneNumber ?? 'Offline',
        passengerEmail: null,
        bookingTime: DateTime.now(),
        totalAmount: trip.price * seatNumbers.length,
        tripData: trip.toJson(),
        status: 'confirmed',
        shortId: _generateShortId());
    // Save with consistency metadata for Search
    final ticketMap = ticket.toJson();
    ticketMap['userData'] = {
      'name': passengerName,
      'email': null,
      'phone': phoneNumber ?? 'Offline',
    };
    await ticketRef.set(ticketMap);
    return ticket;
  }

  Stream<List<Ticket>> getUserTickets(String userId) {
    return _db
        .collection(ticketCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('bookingTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Ticket.fromFirestore(d)).toList());
  }

  // --- FAVORITES (Routes) ---
  // We save the ROUTE (From/To), not the specific scheduled trip instance.

  String _normalizeCity(String city) {
    if (city.trim().isEmpty) return "";
    final trimmed = city.trim();
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  Future<void> toggleFavorite(String userId, Trip trip) async {
    await toggleRouteFavorite(
      userId,
      trip.originCity,
      trip.destinationCity,
      operatorName: trip.operatorName,
      price: trip.price,
    );
  }

  Future<void> toggleRouteFavorite(String userId, String from, String to,
      {String? operatorName, double? price}) async {
    final cleanFrom = _normalizeCity(from);
    final cleanTo = _normalizeCity(to);
    if (cleanFrom.isEmpty || cleanTo.isEmpty) return;

    final id = "${cleanFrom}_${cleanTo}".replaceAll(' ', '_');
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('favorite_routes')
        .doc(id);

    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'fromCity': cleanFrom,
        'toCity': cleanTo,
        'operatorName': operatorName ?? 'Buslink',
        'price': price,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFavorite(String userId, String routeId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorite_routes')
        .doc(routeId)
        .delete();
  }

  Future<bool> isRouteFavorite(
      String userId, String fromCity, String toCity) async {
    final cleanFrom = _normalizeCity(fromCity);
    final cleanTo = _normalizeCity(toCity);
    if (cleanFrom.isEmpty || cleanTo.isEmpty) return false;

    final routeId = "${cleanFrom}_${cleanTo}".replaceAll(' ', '_');
    final snap = await _db
        .collection('users')
        .doc(userId)
        .collection('favorite_routes')
        .doc(routeId)
        .get();
    return snap.exists;
  }

  Stream<List<Map<String, dynamic>>> getUserFavoriteRoutes(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorite_routes')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  // --- LOCATION / REALTIME ---
  Stream<Trip?> getTripRealtimeStream(String tripId) {
    return _db.collection(tripCollection).doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Trip.fromFirestore(doc);
    });
  }

  Future<void> updateTripRealtimeStatus(
      String tripId, Map<String, dynamic> data) async {
    await _db.collection(tripCollection).doc(tripId).update(data);
  }

  // --- MIGRATION TOOL (Temporary) ---

  Future<List<String>> getPassengerPhonesForTrip(String tripId) async {
    final snapshot = await _db
        .collection(ticketCollection)
        .where('tripId', isEqualTo: tripId)
        .where('status', isEqualTo: 'confirmed')
        .get();

    if (snapshot.docs.isEmpty) return [];

    final phones = snapshot.docs
        .map((d) => d.data()['passengerPhone'] as String?)
        .where((p) => p != null && p.isNotEmpty && p != 'N/A')
        .map((p) => p!)
        .toSet() // Deduplicate
        .toList();

    return phones;
  }
}
