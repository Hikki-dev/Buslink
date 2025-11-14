// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_model.dart';

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

  // --- NEW: Method to find a trip by its bus number ---
  Future<Trip?> getTripByBusNumber(String busNumber) async {
    final now = DateTime.now();
    // Look for a bus that departed in the last 6 hours or is departing in the next 12
    final dayStart = now.subtract(const Duration(hours: 6));
    final dayEnd = now.add(const Duration(hours: 12));

    final snapshot = await _db
        .collection(tripCollection)
        .where('busNumber', isEqualTo: busNumber)
        .where('departureTime', isGreaterThanOrEqualTo: dayStart)
        .where('departureTime', isLessThanOrEqualTo: dayEnd)
        .orderBy('departureTime') // Find the one closest to now
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

  Future<List<Trip>> getAllTrips() async {
    final snapshot = await _db.collection(tripCollection).limit(20).get();
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
}
