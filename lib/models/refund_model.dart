import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundStatus { pending, approved, rejected, processed, failed }

enum CancellationStatus { confirmed, reversed }

enum RefundReason {
  changeOfPlans,
  personalEmergency,
  tripDelay,
  tripCancelledByOperator,
  bookingMistake,
  seatOrBusIssue,
  other
}

class RefundRequest {
  final String id;
  final String
      bookingId; // This is actually the ticketId/ref in some contexts, but let's keep separate if needed.
  // Based on errors: "Ref: ${refund.ticketId.substring(0, 8)}..." implies we need ticketId.
  final String ticketId;
  final String tripId;
  final String? paymentId;
  final String? paymentIntentId; // For Stripe refunds
  final String userId; // Was requestedBy, but errors say userId
  final String passengerName;
  final DateTime requestedAt; // This maps to createdAt in UI errors?
  final DateTime createdAt;
  final DateTime updatedAt;
  final double
      amountRequested; // This seems to be the total trip price or similar?
  final double tripPrice;
  final double refundPercentage;
  final double refundAmount;
  final double cancellationFee;

  final RefundStatus status;
  final RefundReason reason;
  final String? otherReasonText;

  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final DateTime? processedAt;

  RefundRequest({
    required this.id,
    required this.bookingId,
    required this.ticketId,
    required this.tripId,
    this.paymentId,
    this.paymentIntentId,
    required this.userId,
    required this.passengerName,
    required this.requestedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.amountRequested,
    required this.tripPrice,
    required this.refundPercentage,
    required this.refundAmount,
    required this.cancellationFee,
    this.status = RefundStatus.pending,
    required this.reason,
    this.otherReasonText,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    this.processedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'ticketId': ticketId,
      'tripId': tripId,
      'paymentId': paymentId,
      'paymentIntentId': paymentIntentId,
      'userId': userId,
      'passengerName': passengerName,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'amountRequested': amountRequested,
      'tripPrice': tripPrice,
      'refundPercentage': refundPercentage,
      'refundAmount': refundAmount,
      'cancellationFee': cancellationFee,
      'status': status.name,
      'reason': reason.name,
      'otherReasonText': otherReasonText,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewNote': reviewNote,
      'processedAt':
          processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }

  factory RefundRequest.fromMap(String id, Map<String, dynamic> map) {
    return RefundRequest(
      id: id,
      bookingId: map['bookingId'] ?? '',
      ticketId: map['ticketId'] ?? '',
      tripId: map['tripId'] ?? '',
      paymentId: map['paymentId'],
      paymentIntentId: map['paymentIntentId'],
      userId:
          map['userId'] ?? map['requestedBy'] ?? '', // Fallback for transition
      passengerName: map['passengerName'] ?? 'Unknown',
      requestedAt:
          (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amountRequested: (map['amountRequested'] as num?)?.toDouble() ?? 0.0,
      tripPrice: (map['tripPrice'] as num?)?.toDouble() ?? 0.0,
      refundPercentage: (map['refundPercentage'] as num?)?.toDouble() ?? 0.0,
      refundAmount: (map['refundAmount'] as num?)?.toDouble() ?? 0.0,
      cancellationFee: (map['cancellationFee'] as num?)?.toDouble() ?? 0.0,
      status: RefundStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RefundStatus.pending,
      ),
      reason: RefundReason.values.firstWhere(
        (e) => e.name == map['reason'],
        orElse: () => RefundReason.other,
      ),
      otherReasonText: map['otherReasonText'],
      reviewedBy: map['reviewedBy'],
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
      reviewNote: map['reviewNote'],
      processedAt: (map['processedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory RefundRequest.fromFirestore(DocumentSnapshot doc) {
    return RefundRequest.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }
}

class Cancellation {
  final String id;
  final String bookingId;
  final String requestedBy;
  final DateTime cancelledAt;
  final String? reason;
  final bool eligibleForRefund;
  final String? eligibilityRule;
  final CancellationStatus status;

  Cancellation({
    required this.id,
    required this.bookingId,
    required this.requestedBy,
    required this.cancelledAt,
    this.reason,
    required this.eligibleForRefund,
    this.eligibilityRule,
    this.status = CancellationStatus.confirmed,
  });

  Map<String, dynamic> toMap() {
    return {
      'bookingId': bookingId,
      'requestedBy': requestedBy,
      'cancelledAt': Timestamp.fromDate(cancelledAt),
      'reason': reason,
      'eligibleForRefund': eligibleForRefund,
      'eligibilityRule': eligibilityRule,
      'status': status.name,
    };
  }

  factory Cancellation.fromMap(String id, Map<String, dynamic> map) {
    return Cancellation(
      id: id,
      bookingId: map['bookingId'] ?? '',
      requestedBy: map['requestedBy'] ?? '',
      cancelledAt: (map['cancelledAt'] as Timestamp).toDate(),
      reason: map['reason'],
      eligibleForRefund: map['eligibleForRefund'] ?? false,
      eligibilityRule: map['eligibilityRule'],
      status: CancellationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CancellationStatus.confirmed,
      ),
    );
  }
}
