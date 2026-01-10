import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/trip_model.dart';
import 'package:intl/intl.dart';

class SmsService {
  static final CollectionReference _outboundMessages =
      FirebaseFirestore.instance.collection('outbound_messages');

  /// simulates sending a ticket copy via SMS (logs to Firestore)
  static Future<void> sendTicketCopy(Ticket ticket) async {
    try {
      if (ticket.passengerPhone.isEmpty) {
        debugPrint("No phone number to send SMS.");
        return;
      }

      // Format Date
      final tripData = ticket.tripData;
      DateTime tripDate;
      if (tripData['departureTime'] is Timestamp) {
        tripDate = (tripData['departureTime'] as Timestamp).toDate();
      } else {
        tripDate = DateTime.parse(tripData['departureTime'].toString());
      }
      final dateStr = DateFormat('MMM d, HH:mm').format(tripDate);

      // Construct Message
      final messageBody = "BusLink: Confirmed! "
          "Ticket ${ticket.shortId ?? ticket.ticketId.substring(0, 4)} "
          "to ${tripData['toCity']} on $dateStr. "
          "Bus: ${tripData['busNumber']}. Seats: ${ticket.seatNumbers.join(',')}. "
          "Show this SMS to conductor.";

      // Log to Firestore (simulates "Outbox")
      await _outboundMessages.add({
        'userId': ticket.userId,
        'bookingId': ticket.ticketId,
        'channel': 'SMS',
        'phoneNumber': ticket.passengerPhone,
        'messageBody': messageBody,
        'status': 'sent', // Simulated success
        'createdAt': FieldValue.serverTimestamp(),
        'sentAt': FieldValue.serverTimestamp(), // Simulated instant send
      });

      debugPrint("SMS Logged: $messageBody -> ${ticket.passengerPhone}");
    } catch (e) {
      debugPrint("Error logging SMS: $e");
    }
  }
}
