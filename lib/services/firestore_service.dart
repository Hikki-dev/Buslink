// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart'; // Your consolidated model

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String tripCollection = 'trips';
  final String ticketCollection = 'tickets';

  // BL-01: Search Logic
  Future<List<Trip>> searchTrips(
    String fromCity,
    String toCity,
    DateTime date,
  ) async {
    // Note: Firestore date queries are complex. For simplicity, we query by city.
    // In a real app, you'd query by a date range (e.g., >= date_start_of_day and < date_end_of_day)
    final snapshot = await _db
        .collection(tripCollection)
        .where('fromCity', isEqualTo: fromCity)
        .where('toCity', isEqualTo: toCity)
        .get();

    if (snapshot.docs.isEmpty) {
      return []; // No trips found
    }

    // Use your fromFirestore factory!
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  // ADM-14: Update Platform
  Future<void> updatePlatform(String tripId, String newPlatform) {
    return _db.collection(tripCollection).doc(tripId).update({
      'platformNumber': newPlatform,
    });
  }

  // ADM-05: Update Status
  Future<void> updateStatus(String tripId, TripStatus status, int delay) {
    return _db.collection(tripCollection).doc(tripId).update({
      'status': status.name, // 'onTime', 'delayed', 'cancelled'
      'delayMinutes': delay,
    });
  }

  // BL-06 / BL-19: Process Booking
  Future<Ticket> processBooking(
    Trip trip,
    List<int> seats,
    String passengerName,
  ) async {
    final ticketRef = _db.collection(ticketCollection).doc();
    final tripRef = _db.collection(tripCollection).doc(trip.id);

    // In a real-world app, you MUST run this as a transaction
    // to prevent two people from booking the same seat.
    await _db.runTransaction((transaction) async {
      DocumentSnapshot freshTripSnap = await transaction.get(tripRef);
      if (!freshTripSnap.exists) {
        throw Exception("Trip does not exist!");
      }
      Trip freshTrip = Trip.fromFirestore(freshTripSnap);

      // Check if any selected seats are already booked
      for (int seat in seats) {
        if (freshTrip.bookedSeats.contains(seat)) {
          throw Exception('Seat $seat is already booked.');
        }
      }

      // All good, update the trip
      transaction.update(tripRef, {
        'bookedSeats': FieldValue.arrayUnion(seats),
      });
    });

    // Create the ticket
    final newTicket = Ticket(
      ticketId: ticketRef.id,
      tripId: trip.id,
      seatNumbers: seats,
      passengerName: passengerName, // Get from auth later
      bookingTime: DateTime.now(),
      amountPaid: trip.price * seats.length,
    );

    // Save the new ticket
    await ticketRef.set(newTicket.toJson()); // From your model

    return newTicket;
  }

  // Helper to get all trips for the admin panel
  Future<List<Trip>> getAllTrips() async {
    final snapshot = await _db.collection(tripCollection).limit(20).get();
    if (snapshot.docs.isEmpty) {
      return []; // No trips found
    }
    return snapshot.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }
}
