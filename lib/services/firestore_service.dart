// lib/services/firestore_service.dart

// FIX: Corrected the import path from 'package.' to 'package:'
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final snapshot = await _db
        .collection(tripCollection)
        .where('fromCity', isEqualTo: fromCity)
        .where('toCity', isEqualTo: toCity)
        // Add date query here if needed
        .get();

    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
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
    String passengerName,
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
      seatNumbers: seats,
      passengerName: passengerName,
      passengerPhone: "0771234567", // Mock phone, get from auth/UI later
      bookingTime: DateTime.now(),
      totalAmount: trip.price * seats.length,
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
}
