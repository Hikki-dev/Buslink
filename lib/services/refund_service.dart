import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/refund_model.dart';

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

    if (hours >= 48) {
      refundPercentage = 1.0; // 100%
    } else if (hours >= 24) {
      refundPercentage = 0.90;
    } else if (hours >= 6) {
      refundPercentage = 0.75;
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

    // Update Ticket Status to indicate refund requested?
    // Maybe 'refund_pending'? For now keep 'confirmed' but add flag?
    // Or simpler: just rely on Refund collection.

    // Create Notification for Admin? (Via Cloud Function usually, or here)
    // Create Notification for User
    await _db.collection('notifications').add({
      'userId': request.userId,
      'title': 'Refund Request Received',
      'body':
          'Your refund request for trip to ${request.tripId} has been received.', // Better text needed
      'type': 'refund_update',
      'relatedId': request.id,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }
}
