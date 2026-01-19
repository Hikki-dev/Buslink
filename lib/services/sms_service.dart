import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
// For debugPrint
import 'dart:io';

class SmsService {
  static final CollectionReference _outboundMessages =
      FirebaseFirestore.instance.collection('outbound_messages');

  /// Launches the device's SMS app with a pre-filled message.
  static Future<bool> sendSMS(
      {required String phone, required String message}) async {
    try {
      if (phone.isEmpty) return false;

      // Clean phone number
      final cleanPhone = phone.replaceAll(RegExp(r'\s+|-'), '');

      // Encode message
      final String encodedMessage = Uri.encodeComponent(message);

      // Construct URI based on platform
      Uri uri;
      if (kIsWeb) {
        uri = Uri.parse('sms:$cleanPhone?body=$encodedMessage');
      } else if (Platform.isAndroid) {
        // Android often prefers body
        uri = Uri.parse('sms:$cleanPhone?body=$encodedMessage');
      } else if (Platform.isIOS) {
        // iOS strict separation
        uri = Uri.parse('sms:$cleanPhone&body=$encodedMessage');
      } else {
        uri = Uri.parse('sms:$cleanPhone?body=$encodedMessage');
      }

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        // Log "Attempted" to Firestore
        await _logSmsAttempt(phone, message, 'launched');
        return true;
      } else {
        debugPrint("Could not launch SMS url: $uri");
        return false;
      }
    } catch (e) {
      debugPrint("Error sending SMS: $e");
      return false;
    }
  }

  /// Automated Server-Side Trigger (No UI Launch)
  /// Queues messages to Firestore for processing by Cloud Functions.
  static Future<void> queueBatchSMS(List<String> phones, String message) async {
    if (phones.isEmpty) return;

    final validPhones =
        phones.where((p) => p.isNotEmpty && p.length > 7).toSet().toList();

    if (validPhones.isEmpty) return;

    try {
      // Create a batch or single document depending on Extension logic.
      // E.g., 'messages' collection where each doc is a message.
      WriteBatch batch = FirebaseFirestore.instance.batch();

      for (String phone in validPhones) {
        DocumentReference docRef = _outboundMessages.doc();
        batch.set(docRef, {
          'to': phone, // Standard field for extensions
          'body': message,
          'status': 'queued',
          'channel': 'SMS_AUTOMATED', // Distinguish from manual
          'createdAt': FieldValue.serverTimestamp(),
          'deliveryStatus': 'pending'
        });
      }

      await batch.commit();
      debugPrint("Queued ${validPhones.length} SMS messages to Firestore.");
    } catch (e) {
      debugPrint("Error queuing SMS batch: $e");
    }
  }

  /// Legacy Batch (Manual Launch) - Kept for fallback if needed, but not used by Conductor
  static Future<void> sendBatchSMS(List<String> phones, String message) async {
    if (phones.isEmpty) return;
    final uniquePhones = phones.toSet().toList();
    final String recipientString = uniquePhones.join(',');
    await sendSMS(phone: recipientString, message: message);
  }

  static Future<void> _logSmsAttempt(
      String phone, String message, String status) async {
    try {
      await _outboundMessages.add({
        'channel': 'SMS_CLIENT_SIDE',
        'phoneNumber': phone,
        'messageBody': message,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error logging SMS attempt: $e");
    }
  }

  /// Sends a ticket copy via SMS (Client-side trigger)
  static Future<bool> sendTicketCopy(dynamic ticket) async {
    try {
      final phone = (ticket.passengerPhone as String? ?? '');
      if (phone.isEmpty) return false;

      final tripData = ticket.tripData as Map<String, dynamic>;
      final messageBody = "BusLink Ticket: ${ticket.ticketId.substring(0, 4)} "
          "From ${tripData['originCity'] ?? tripData['fromCity']} To ${tripData['destinationCity'] ?? tripData['toCity']}. "
          "Bus: ${tripData['busNumber']}. Seat: ${(ticket.seatNumbers as List).join(',')}. "
          "Show to conductor.";

      return await sendSMS(phone: phone, message: messageBody);
    } catch (e) {
      debugPrint("Error preparing ticket SMS: $e");
      return false;
    }
  }

  /// Sends a trip status update to multiple passengers (AUTOMATED)
  static Future<void> sendTripStatusUpdate(
      List<String> phones, String status, String message) async {
    if (phones.isEmpty) return;

    final fullMessage = "BusLink Update: Your trip is now $status. $message";

    // Use Queue instead of Launch
    await queueBatchSMS(phones, fullMessage);
  }
}
