import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/refund_model.dart';
import 'notification_service.dart' as import_notification_service;

class RefundService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Eligibility Check
  Future<Map<String, dynamic>> checkRefundEligibility(
      String tripId, DateTime departureTime) async {
    // Rules:
    // 1. Must be >= 6 hours before departure
    // 2. Trip must not be DEPARTED/CANCELLED (handled by UI usually, but good to check)

    final now = DateTime.now();
    final difference = departureTime.difference(now);

    if (difference.inHours < 6) {
      return {
        'eligible': false,
        'reason': 'Refunds are only available up to 6 hours before departure.'
      };
    }

    // Check Trip Status if needed (optional if passed in)
    final tripDoc = await _db.collection('trips').doc(tripId).get();
    if (tripDoc.exists) {
      final status = tripDoc.data()?['status'];
      if (status == 'departed' ||
          status == 'cancelled' ||
          status == 'arrived') {
        return {
          'eligible': false,
          'reason': 'Trip has already ${status ?? 'departed'}.'
        };
      }
    }

    return {'eligible': true};
  }

  // 2. Calculate Refund
  Map<String, double> calculateRefundAmount(
      double totalPaid, DateTime departureTime) {
    // Simple logic:
    // > 48 hours: 100% refund (minus small processing fee? assume 0 for now or 5%)
    // 24-48 hours: 90%
    // 6-24 hours: 75%
    // < 6 hours: 0%

    final now = DateTime.now();
    final difference = departureTime.difference(now);
    final hours = difference.inHours;

    double refundPercentage = 0.0;

    if (hours >= 24) {
      refundPercentage = 0.90;
    } else if (hours >= 6) {
      refundPercentage = 0.50;
    } else {
      refundPercentage = 0.0;
    }

    final refundAmount = totalPaid * refundPercentage;
    final cancellationFee = totalPaid - refundAmount;

    return {
      'refundAmount': refundAmount,
      'cancellationFee': cancellationFee,
      'percentage': refundPercentage,
    };
  }

  // 3. Create Request
  Future<void> createRefundRequest(RefundRequest request) async {
    await _db.collection('refunds').doc(request.id).set(request.toMap());

    // Update Ticket Status
    await _db
        .collection('tickets')
        .doc(request.ticketId)
        .update({'status': 'refund_requested'});

    // Create Notification for User
    String userName = "Passenger";
    if (request.passengerName.isNotEmpty) {
      userName = request.passengerName.split(' ').first;
    }

    // Fetch Trip Details for formatted message
    String tripDescription = request.tripId;
    try {
      final tripDoc = await _db.collection('trips').doc(request.tripId).get();
      if (tripDoc.exists) {
        final data = tripDoc.data();
        if (data != null) {
          final from = data['originCity'] ?? data['fromCity'] ?? '';
          final to = data['destinationCity'] ?? data['toCity'] ?? '';
          final via = data['via'] ?? '';
          if (from.isNotEmpty && to.isNotEmpty) {
            tripDescription = "$from - $to";
            if (via.isNotEmpty && via != 'Direct') {
              tripDescription += " Via $via";
            }
          }
        }
      }
    } catch (e) {
      // Fallback
    }

    await import_notification_service.NotificationService.sendNotificationToUser(
        userId: request.userId,
        title: 'Refund Request Received',
        body:
            'Hello $userName, we received your refund request for trip $tripDescription. We will review it shortly.',
        type: 'refundStatus',
        relatedId: request.id);

    // Immediate Local Notification (Reliability Fallback)
    await import_notification_service.NotificationService.showLocalNotification(
        id: request.id.hashCode,
        title: 'Refund Request Received',
        body:
            'Hello $userName, we received your refund request for trip $tripDescription.',
        payload: request.id);
  }
}
