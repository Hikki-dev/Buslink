import 'package:cloud_firestore/cloud_firestore.dart';

enum RefundTransactionStatus { pending, success, failed }

class RefundTransaction {
  final String id;
  final String refundRequestId;
  final String ticketId;
  final String userId;
  final double amount;
  final String currency;
  final String? stripePaymentIntentId;
  final String? stripeRefundId;
  final RefundTransactionStatus status;
  final DateTime processedAt;
  final String? failureReason;

  RefundTransaction({
    required this.id,
    required this.refundRequestId,
    required this.ticketId,
    required this.userId,
    required this.amount,
    required this.currency,
    this.stripePaymentIntentId,
    this.stripeRefundId,
    required this.status,
    required this.processedAt,
    this.failureReason,
  });

  factory RefundTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RefundTransaction(
      id: doc.id,
      refundRequestId: data['refundRequestId'] ?? '',
      ticketId: data['ticketId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'LKR',
      stripePaymentIntentId: data['stripePaymentIntentId'],
      stripeRefundId: data['stripeRefundId'],
      status: RefundTransactionStatus.values.firstWhere(
        (e) => e.name == (data['status'] ?? 'pending'),
        orElse: () => RefundTransactionStatus.pending,
      ),
      processedAt:
          (data['processedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      failureReason: data['failureReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'refundRequestId': refundRequestId,
      'ticketId': ticketId,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeRefundId': stripeRefundId,
      'status': status.name,
      'processedAt': Timestamp.fromDate(processedAt),
      'failureReason': failureReason,
    };
  }
}
