// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';
import '../models/route_model.dart';

import 'dart:math';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String tripCollection = 'trips';
  final String ticketCollection = 'tickets';
  final String userCollection = 'users';
  final String routeCollection = 'routes';

  // Helper to generate 4-char alphanumeric ID
  String _generateShortId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        4, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<DocumentSnapshot> getUserData(String uid) {
    return _db.collection(userCollection).doc(uid).get();
  }

  Future<List<Trip>> searchTrips(
    String fromCity,
    String toCity,
    DateTime date,
  ) async {
    final DateTime dayStart = DateTime(date.year, date.month, date.day);
    final DateTime dayEnd = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    );

    // Normalize inputs (Title Case)
    // Assumes DB stores "Colombo", "Kandy" etc.
    final String safeFrom = fromCity.isEmpty
        ? ""
        : fromCity[0].toUpperCase() + fromCity.substring(1).toLowerCase();
    final String safeTo = toCity.isEmpty
        ? ""
        : toCity[0].toUpperCase() + toCity.substring(1).toLowerCase();

    final snapshot = await _db
        .collection(tripCollection)
        .where('fromCity', isEqualTo: safeFrom)
        .where('toCity', isEqualTo: safeTo)
        .where('departureTime', isGreaterThanOrEqualTo: dayStart)
        .where('departureTime', isLessThanOrEqualTo: dayEnd)
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  Future<List<Trip>> getTripsByDate(DateTime start, DateTime end) async {
    final snapshot = await _db
        .collection(tripCollection)
        .where('departureTime', isGreaterThanOrEqualTo: start)
        .where('departureTime', isLessThanOrEqualTo: end)
        .orderBy('departureTime')
        .get();

    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  // --- NEW: Get Trips by Conductor ---
  Future<List<Trip>> getTripsByConductor(String conductorId) async {
    final now = DateTime.now();
    // Show trips from today onwards (or maybe slightly in the past to show active ones)
    final start = DateTime(now.year, now.month, now.day);

    final snapshot = await _db
        .collection(tripCollection)
        .where('conductorId', isEqualTo: conductorId)
        .where('departureTime', isGreaterThanOrEqualTo: start)
        .orderBy('departureTime')
        .get();

    if (snapshot.docs.isEmpty) return [];
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  // --- NEW: Method to find a trip by its bus number ---
  Future<Trip?> getTripByBusNumber(String busNumber) async {
    final now = DateTime.now();
    final dayStart = now.subtract(const Duration(hours: 6));
    final dayEnd = now.add(const Duration(hours: 4));

    final snapshot = await _db
        .collection(tripCollection)
        .where('busNumber', isEqualTo: busNumber)
        .where('departureTime', isGreaterThanOrEqualTo: dayStart)
        .where('departureTime', isLessThanOrEqualTo: dayEnd)
        .orderBy('departureTime')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }
    return Trip.fromFirestore(snapshot.docs.first);
  }

  Future<void> updateTripDetails(String tripId, Map<String, dynamic> data) {
    return _db.collection(tripCollection).doc(tripId).update(data);
  }

  // --- ADDED: Create Trip ---
  Future<void> addTrip(Map<String, dynamic> data) {
    return _db.collection(tripCollection).add(data);
  }

  // --- ADDED: Delete Trip ---
  Future<void> deleteTrip(String tripId) {
    return _db.collection(tripCollection).doc(tripId).delete();
  }

  Future<void> updatePlatform(String tripId, String newPlatform) {
    return _db.collection(tripCollection).doc(tripId).update({
      'platformNumber': newPlatform,
    });
  }

  Future<void> updateStatus(String tripId, TripStatus status, int delay) {
    return _db.collection(tripCollection).doc(tripId).update({
      'status': status.name,
      'delayMinutes': delay,
    });
  }

  // --- ADDED: Stream for Real-time Trip Status ---
  Stream<Trip> getTripStream(String tripId) {
    return _db.collection(tripCollection).doc(tripId).snapshots().map((doc) {
      if (!doc.exists) {
        throw Exception("Trip not found");
      }
      return Trip.fromFirestore(doc);
    });
  }

  Future<Ticket> processBooking(
    Trip trip,
    List<int> seats,
    User user,
  ) async {
    final ticketRef = _db.collection(ticketCollection).doc();
    final tripRef = _db.collection(tripCollection).doc(trip.id);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot freshTripSnap = await transaction.get(tripRef);
      if (!freshTripSnap.exists) {
        throw Exception("Trip does not exist!");
      }
      Trip freshTrip = Trip.fromFirestore(freshTripSnap);

      for (int seat in seats) {
        if (freshTrip.bookedSeats.contains(seat)) {
          throw Exception('Seat $seat is already booked.');
        }
      }

      transaction.update(tripRef, {
        'bookedSeats': FieldValue.arrayUnion(seats),
      });
    });

    final newTicket = Ticket(
      ticketId: ticketRef.id,
      tripId: trip.id,
      userId: user.uid,
      seatNumbers: seats,
      passengerName: user.displayName ?? user.email ?? 'Guest',
      passengerPhone: user.phoneNumber ?? "N/A",
      bookingTime: DateTime.now(),
      totalAmount: trip.price * seats.length,
      tripData: {
        'fromCity': trip.fromCity,
        'toCity': trip.toCity,
        'operatorName': trip.operatorName,
        'busNumber': trip.busNumber,
        'departureTime': Timestamp.fromDate(trip.departureTime),
        'arrivalTime': Timestamp.fromDate(trip.arrivalTime),
      },
      shortId: _generateShortId(),
    );

    await ticketRef.set(newTicket.toJson());
    return newTicket;
  }

  // --- ADDED: Route Handling ---

  // --- ADDED: Dynamic City List ---
  Future<List<String>> getAvailableCities() async {
    // 1. Try fetching from 'routes' collection first (cleaner source)
    final routeSnap = await _db.collection(routeCollection).get();
    final Set<String> cities = {};

    if (routeSnap.docs.isNotEmpty) {
      for (var doc in routeSnap.docs) {
        final data = doc.data();
        if (data['fromCity'] != null) cities.add(data['fromCity'].toString());
        if (data['toCity'] != null) cities.add(data['toCity'].toString());
      }
    } else {
      // 2. Fallback to 'trips' if no routes defined
      final tripSnap = await _db.collection(tripCollection).limit(50).get();
      for (var doc in tripSnap.docs) {
        final data = doc.data();
        if (data['fromCity'] != null) cities.add(data['fromCity'].toString());
        if (data['toCity'] != null) cities.add(data['toCity'].toString());
      }
    }

    // If absolutely nothing, return empty list
    if (cities.isEmpty) {
      return [];
    }

    return cities.toList()..sort();
  }

  Future<List<Trip>> getAllTrips() async {
    final snapshot = await _db.collection(tripCollection).limit(50).get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  Stream<List<Ticket>> getUserTickets(String userId) {
    return _db
        .collection(ticketCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return [];
      }
      return snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList();
    });
  }

  // --- ADDED: Get Single Ticket by ID ---
  Future<Ticket?> getTicket(String ticketId) async {
    final doc = await _db.collection(ticketCollection).doc(ticketId).get();
    if (doc.exists) {
      return Ticket.fromFirestore(doc);
    }
    return null;
  }

  // --- FAVORITES ---
  final String favoritesCollection = 'favorites';

  Future<void> removeFavorite(String userId, String tripId) async {
    // Try both collections to ensure cleanup
    final docRefLegacy = _db
        .collection(userCollection)
        .doc(userId)
        .collection(favoritesCollection)
        .doc(tripId);

    final docRefRoutes = _db
        .collection(userCollection)
        .doc(userId)
        .collection('favorite_routes')
        .doc(tripId);

    await Future.wait([
      docRefLegacy.delete(),
      docRefRoutes.delete(),
    ]);
  }

  Future<void> toggleFavorite(String userId, Trip trip) async {
    final docRef = _db
        .collection(userCollection)
        .doc(userId)
        .collection(favoritesCollection)
        .doc(trip.id);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      await docRef.delete();
    } else {
      // Save minimal trip info for favorites list
      await docRef.set({
        'fromCity': trip.fromCity,
        'toCity': trip.toCity,
        'operatorName': trip.operatorName,
        'price': trip.price,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> toggleRouteFavorite(
      String userId, String fromCity, String toCity,
      {String? operatorName, double? price}) async {
    try {
      final safeFrom = fromCity.replaceAll('/', '-');
      final safeTo = toCity.replaceAll('/', '-');
      final routeId = "${safeFrom}_$safeTo";

      final docRef = _db
          .collection(userCollection)
          .doc(userId)
          .collection('favorite_routes')
          .doc(routeId);
      final docSnap = await docRef.get();

      if (docSnap.exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          'fromCity': fromCity,
          'toCity': toCity,
          'operatorName': operatorName ?? '',
          'price': price,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error toggling route favorite: $e");
    }
  }

  Future<bool> isTripFavorite(String userId, String tripId) async {
    final doc = await _db
        .collection(userCollection)
        .doc(userId)
        .collection(favoritesCollection)
        .doc(tripId)
        .get();
    return doc.exists;
  }

  Future<bool> isRouteFavorite(
      String userId, String fromCity, String toCity) async {
    try {
      // Sanitize ID to prevent path errors if cities contain '/'
      final safeFrom = fromCity.replaceAll('/', '-');
      final safeTo = toCity.replaceAll('/', '-');
      final routeId = "${safeFrom}_$safeTo";

      final doc = await _db
          .collection(userCollection)
          .doc(userId)
          .collection('favorite_routes')
          .doc(routeId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint("Error checking route favorite: $e");
      return false; // Fail safe
    }
  }

  Stream<List<Map<String, dynamic>>> getUserFavorites(String userId) {
    return _db
        .collection(userCollection)
        .doc(userId)
        .collection(favoritesCollection)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<List<Map<String, dynamic>>> getUserFavoriteRoutes(String userId) {
    return _db
        .collection(userCollection)
        .doc(userId)
        .collection('favorite_routes')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map(
            (snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // --- User Management ---

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id; // Ensure UID is available for updates
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

  // --- 8. Pending Bookings (For Redirect Flows like Stripe Checkout) ---
  Future<String> createPendingBooking(
      Trip trip, List<int> seatNumbers, User user) async {
    final tripRef = _db.collection('trips').doc(trip.id);
    final freshTripSnap = await tripRef.get();

    if (freshTripSnap.exists) {
      final freshTrip = Trip.fromFirestore(freshTripSnap);
      for (int seat in seatNumbers) {
        if (freshTrip.bookedSeats.contains(seat)) {
          throw Exception("Seat(s) no longer available. Please reselect.");
        }
      }
    }

    final bookingRef = _db.collection('tickets').doc();

    final ticketData = {
      'tripId': trip.id,
      'userId': user.uid,
      'userEmail': user.email,
      'userName': user.displayName ?? "Traveler",
      'seatNumbers': seatNumbers,
      'totalAmount': trip.price * seatNumbers.length,
      'bookingTime': FieldValue.serverTimestamp(),
      'status': 'pending_payment', // Initial status
      'tripData': trip.toMap(), // Snapshot of trip details
    };

    await bookingRef.set(ticketData);
    return bookingRef.id;
  }

  Future<List<String>> createBulkPendingBookings(
      List<Trip> trips, List<int> seatNumbers, User user) async {
    final WriteBatch batch = _db.batch();
    final List<String> bookingIds = [];

    // 1. Check Availability for ALL trips
    for (final trip in trips) {
      final tripRef = _db.collection('trips').doc(trip.id);
      final freshTripSnap = await tripRef.get();
      if (freshTripSnap.exists) {
        final freshTrip = Trip.fromFirestore(freshTripSnap);
        for (int seat in seatNumbers) {
          if (freshTrip.bookedSeats.contains(seat)) {
            throw Exception(
                "Seat $seat is no longer available on bus ${trip.busNumber} for ${trip.departureTime.toString().split(' ')[0]}.");
          }
        }
      }
    }

    // 2. Prepare Writes
    for (final trip in trips) {
      final bookingRef = _db.collection('tickets').doc();
      bookingIds.add(bookingRef.id);

      final ticketData = {
        'tripId': trip.id,
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? "Traveler",
        'seatNumbers': seatNumbers,
        'totalAmount': trip.price * seatNumbers.length,
        'bookingTime': FieldValue.serverTimestamp(),
        'status': 'pending_payment',
        'tripData': trip.toMap(),
      };
      batch.set(bookingRef, ticketData);
    }

    // 3. Commit
    await batch.commit();
    return bookingIds;
  }

  // --- 9. Confirm Persistent Booking (Called after Succesful Payment) ---
  Future<Ticket> confirmBooking(String bookingId) async {
    final ticketRef = _db.collection('tickets').doc(bookingId);

    return await _db.runTransaction((transaction) async {
      final ticketSnap = await transaction.get(ticketRef);
      if (!ticketSnap.exists) {
        throw Exception("Booking not found!");
      }

      final ticketData = ticketSnap.data() as Map<String, dynamic>;
      // If already confirmed, return it
      if (ticketData['status'] == 'confirmed') {
        return Ticket.fromFirestore(ticketSnap);
      }

      final String tripId = ticketData['tripId'];
      // Explicitly cast to List<int> to ensure arrayUnion works
      final List<dynamic> rawSeats = ticketData['seatNumbers'] ?? [];
      final List<int> seats = rawSeats.map((e) => e as int).toList();

      debugPrint(
          "Confirming Booking: $bookingId for Trip: $tripId Seats: $seats");

      final tripRef = _db.collection('trips').doc(tripId);
      final tripSnap = await transaction.get(tripRef);

      if (!tripSnap.exists) {
        throw Exception("Trip not found!");
      }

      final trip = Trip.fromFirestore(tripSnap);

      // Verify availability again
      for (int seat in seats) {
        if (trip.bookedSeats.contains(seat)) {
          throw Exception(
              "Seats $seat are no longer available. Please contact support.");
        }
      }

      // Lock seats
      transaction.update(tripRef, {
        'bookedSeats': FieldValue.arrayUnion(seats),
      });

      debugPrint("Trip $tripId updated with booked seats: $seats");

      // Confirm ticket
      final shortId = _generateShortId();
      transaction.update(ticketRef, {
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
        'shortId': shortId,
      });

      return Ticket.fromMap({
        ...ticketData,
        'status': 'confirmed',
        'shortId': shortId,
        'id': bookingId,
      }, bookingId);
    });
  }

  // --- ADDED: Get Trip by ID ---
  Future<Trip?> getTrip(String tripId) async {
    final doc = await _db.collection(tripCollection).doc(tripId).get();
    if (doc.exists) {
      return Trip.fromFirestore(doc);
    }
    return null;
  }

  // --- ADDED: Offline (Cash) Booking ---
  Future<Ticket> createOfflineBooking(
      Trip trip, List<int> seats, String passengerName, User? conductor) async {
    final ticketRef = _db.collection(ticketCollection).doc();
    final tripRef = _db.collection(tripCollection).doc(trip.id);

    return _db.runTransaction((transaction) async {
      final freshTripSnap = await transaction.get(tripRef);
      if (!freshTripSnap.exists) throw Exception("Trip missing");

      final freshTrip = Trip.fromFirestore(freshTripSnap);

      for (int seat in seats) {
        if (freshTrip.bookedSeats.contains(seat)) {
          throw Exception('Seat $seat is already booked.');
        }
      }

      transaction.update(tripRef, {
        'bookedSeats': FieldValue.arrayUnion(seats),
      });

      final ticketData = {
        'ticketId': ticketRef.id,
        'tripId': trip.id,
        'userId': conductor?.uid ?? 'offline_admin',
        'passengerName': passengerName,
        'passengerPhone': 'N/A',
        'userEmail': 'offline@buslink.com',
        'seatNumbers': seats,
        'totalAmount': trip.price * seats.length,
        'bookingTime': Timestamp.fromDate(DateTime.now()),
        'status': 'confirmed',
        'paymentMethod': 'cash',
        'issuedBy': conductor?.email ?? 'System',
        'tripData': trip.toMap(),
        'shortId': _generateShortId(),
      };

      transaction.set(ticketRef, ticketData);
      return Ticket.fromMap(ticketData, ticketRef.id);
    });
  }

  // Feedback
  Future<void> submitFeedback(Map<String, dynamic> feedbackData) async {
    await _db.collection('feedback').add(feedbackData);
  }

  // --- ADDED: Verify Ticket (manual or scan) ---
  Future<Ticket?> verifyTicket(String ticketId) async {
    if (ticketId.isEmpty) return null;

    // 1. Check Full ID
    final docRef = _db.collection(ticketCollection).doc(ticketId);
    final docSnap = await docRef.get();
    if (docSnap.exists) {
      return Ticket.fromFirestore(docSnap);
    }

    // 2. Check Short ID (Case Insensitive)
    final querySnap = await _db
        .collection(ticketCollection)
        .where('shortId', isEqualTo: ticketId.toUpperCase())
        .limit(1)
        .get();

    if (querySnap.docs.isNotEmpty) {
      return Ticket.fromFirestore(querySnap.docs.first);
    }

    return null;
  }
  // --- ROUTE MANAGEMENT ---

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
}
