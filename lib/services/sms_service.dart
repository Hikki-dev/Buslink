import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
// For debugPrint
import 'dart:io';

class SmsService {
  static final CollectionReference _outboundMessages =
      FirebaseFirestore.instance.collection('outbound_messages');

  /// Launches the device's SMS app with a pre-filled message.
  static Future<void> sendSMS(
      {required String phone, required String message}) async {
    try {
      if (phone.isEmpty) return;

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
        await launchUrl(uri);
        // Log "Attempted" to Firestore
        await _logSmsAttempt(phone, message);
      } else {
        debugPrint("Could not launch SMS url: $uri");
        // Fallback? Copy to clipboard?
      }
    } catch (e) {
      debugPrint("Error sending SMS: $e");
    }
  }

  /// Batch SMS (Looping - Admin must press back/send multiple times or use Group if supported)
  /// Note: 'sms:number1,number2' works on some Androids, iOS does not support pre-filling multiple recipients easily via standard scheme.
  /// Strategy: We will try to launch one "Group" SMS if possible, or just log warn.
  /// Actually, standard "sms:1,2,3" works on many modern Androids. iOS is tricky.
  static Future<void> sendBatchSMS(List<String> phones, String message) async {
    if (phones.isEmpty) return;

    // Deduplicate
    final uniquePhones = phones.toSet().toList();

    // Attempt comma separated (Android style)
    final String recipientString = uniquePhones.join(',');

    // For now, simpler to just treat as single launch
    // If this fails on iOS, we might need a specific package, but let's try standard scheme first.
    await sendSMS(phone: recipientString, message: message);
  }

  static Future<void> _logSmsAttempt(String phone, String message) async {
    try {
      await _outboundMessages.add({
        'channel': 'SMS_CLIENT_SIDE',
        'phoneNumber': phone,
        'messageBody': message,
        'status': 'launched',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error logging SMS attempt: $e");
    }
  }

  /// Sends a ticket copy via SMS (Client-side trigger)
  static Future<void> sendTicketCopy(dynamic ticket) async {
    // Dynamic to accept Ticket model without importing if avoiding circular deps
    // Or just cast if we know.
    // Re-using exiting logic but replacing implementation
    try {
      // Access fields safely
      final phone = (ticket.passengerPhone as String? ?? '');
      if (phone.isEmpty) {
        debugPrint("No phone number to send SMS.");
        return;
      }

      final tripData = ticket.tripData as Map<String, dynamic>;
      // Construct Message
      final messageBody = "BusLink Ticket: ${ticket.ticketId.substring(0, 4)} "
          "From ${tripData['originCity'] ?? tripData['fromCity']} To ${tripData['destinationCity'] ?? tripData['toCity']}. "
          "Bus: ${tripData['busNumber']}. Seat: ${(ticket.seatNumbers as List).join(',')}. "
          "Show to conductor.";

      await sendSMS(phone: phone, message: messageBody);
    } catch (e) {
      debugPrint("Error preparing ticket SMS: $e");
    }
  }

  /// Sends a trip status update to multiple passengers
  static Future<void> sendTripStatusUpdate(
      List<String> phones, String status, String message) async {
    if (phones.isEmpty) return;

    // Filter out invalid numbers
    final validPhones =
        phones.where((p) => p.isNotEmpty && p.length > 7).toList();

    if (validPhones.isEmpty) return;

    final fullMessage = "BusLink Update: Your trip is now $status. $message";

    // Attempt Batch
    await sendBatchSMS(validPhones, fullMessage);
  }
}
