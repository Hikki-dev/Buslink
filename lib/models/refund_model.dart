import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundStatus { pending, approved, rejected }

enum RefundProcessingStatus { initiated, processing, completed, failed }

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
  final String ticketId;
  final String userId;
  final String passengerName;
  final String tripId;
  final RefundReason reason;
  final String? otherReasonText;
  final RefundStatus status;
  final RefundProcessingStatus processingStatus;
  final double tripPrice;
  final double refundPercentage; // 0.0 to 1.0 (e.g. 0.9 for 90%)
  final double refundAmount;
  final double cancellationFee;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Payment Info
  final String? paymentIntentId;
  final String? refundTransactionId;

  RefundRequest({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.passengerName,
    required this.tripId,
    required this.reason,
    this.otherReasonText,
    this.status = RefundStatus.pending,
    this.processingStatus = RefundProcessingStatus.initiated,
    required this.tripPrice,
    required this.refundPercentage,
    required this.refundAmount,
    required this.cancellationFee,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.paymentIntentId,
    this.refundTransactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'userId': userId,
      'passengerName': passengerName,
      'tripId': tripId,
      'reason': reason.name,
      'otherReasonText': otherReasonText,
      'status': status.name,
      'processingStatus': processingStatus.name,
      'tripPrice': tripPrice,
      'refundPercentage': refundPercentage,
      'refundAmount': refundAmount,
      'cancellationFee': cancellationFee,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'paymentIntentId': paymentIntentId,
      'refundTransactionId': refundTransactionId,
    };
  }

  factory RefundRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RefundRequest(
      id: doc.id,
      ticketId: data['ticketId'] ?? '',
      userId: data['userId'] ?? '',
      passengerName: data['passengerName'] ?? '',
      tripId: data['tripId'] ?? '',
      reason: RefundReason.values.firstWhere(
        (e) => e.name == (data['reason'] ?? 'other'),
        orElse: () => RefundReason.other,
      ),
      otherReasonText: data['otherReasonText'],
      status: RefundStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => RefundStatus.pending,
      ),
      processingStatus: RefundProcessingStatus.values.firstWhere(
        (e) => e.name == (data['processingStatus'] ?? 'initiated'),
        orElse: () => RefundProcessingStatus.initiated,
      ),
      tripPrice: (data['tripPrice'] ?? 0).toDouble(),
      refundPercentage: (data['refundPercentage'] ?? 0).toDouble(),
      refundAmount: (data['refundAmount'] ?? 0).toDouble(),
      cancellationFee: (data['cancellationFee'] ?? 0).toDouble(),
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      paymentIntentId: data['paymentIntentId'],
      refundTransactionId: data['refundTransactionId'],
    );
  }
}
