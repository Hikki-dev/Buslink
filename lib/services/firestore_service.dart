// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- 1. IMPORT FIREBASE AUTH
import '../models/trip_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String tripCollection = 'trips';
  final String ticketCollection = 'tickets';

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

  // ... (updatePlatform and updateStatus are unchanged) ...
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

  // --- 2. UPDATE THIS FUNCTION SIGNATURE ---
  Future<Ticket> processBooking(
    Trip trip,
    List<int> seats,
    User user, // <-- Use the User object
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

    // --- 3. UPDATE TICKET CREATION ---
    final newTicket = Ticket(
      ticketId: ticketRef.id,
      tripId: trip.id,
      userId: user.uid, // <-- Save the user's ID
      seatNumbers: seats,
      passengerName:
          user.displayName ?? user.email ?? 'Guest', // <-- Use user's name
      passengerPhone:
          user.phoneNumber ?? "N/A", // <-- Use user's phone if available
      bookingTime: DateTime.now(),
      totalAmount: trip.price * seats.length,
      // Save a copy of the trip data for easy display on "My Tickets"
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

  // --- 4. ADD NEW FUNCTION TO GET USER'S TICKETS ---
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
