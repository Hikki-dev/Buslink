// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String tripCollection = 'trips';
  final String ticketCollection = 'tickets';
  final String userCollection = 'users';

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

    final snapshot = await _db
        .collection(tripCollection)
        .where('fromCity', isEqualTo: fromCity)
        .where('toCity', isEqualTo: toCity)
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

  // --- NEW: Method to find a trip by its bus number ---
  Future<Trip?> getTripByBusNumber(String busNumber) async {
    final now = DateTime.now();
    final dayStart = now.subtract(const Duration(hours: 6));
    final dayEnd = now.add(const Duration(hours: 12));

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
    );

    await ticketRef.set(newTicket.toJson());
    return newTicket;
  }

  // --- ADDED: Route Handling ---
  final String routeCollection = 'routes';

  Future<DocumentReference> addRoute(Map<String, dynamic> data) {
    return _db.collection(routeCollection).add(data);
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
      String userId, String fromCity, String toCity) async {
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
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> updateUserRole(String uid, String newRole) async {
    await _db.collection('users').doc(uid).update({'role': newRole});
  }
}
