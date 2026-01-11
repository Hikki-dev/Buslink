import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/refund_model.dart';
import '../../../models/refund_transaction_model.dart';
import '../../../services/stripe_service.dart';

import '../../../../services/notification_service.dart';

class AdminRefundDetailsScreen extends StatefulWidget {
  final String refundId;
  const AdminRefundDetailsScreen({super.key, required this.refundId});

  @override
  State<AdminRefundDetailsScreen> createState() =>
      _AdminRefundDetailsScreenState();
}

class _AdminRefundDetailsScreenState extends State<AdminRefundDetailsScreen> {
  final TextEditingController _rejectReasonController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Refund Details")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('refunds')
            .doc(widget.refundId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final refund = RefundRequest.fromFirestore(snapshot.data!);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(refund),
                const SizedBox(height: 24),
                _buildDetailsCard(refund),
                const SizedBox(height: 32),
                if (refund.status == RefundStatus.pending)
                  _buildActionButtons(refund),
                if (refund.status != RefundStatus.pending)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: refund.status == RefundStatus.approved
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    child: Text(
                      "This refund has been ${refund.status.name.toUpperCase()}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: refund.status == RefundStatus.approved
                              ? Colors.green
                              : Colors.red),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(RefundRequest refund) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Text(refund.passengerName[0],
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(refund.passengerName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Booking Ref: ${refund.ticketId}",
                style: const TextStyle(color: Colors.grey)),
          ],
        )
      ],
    );
  }

  Widget _buildDetailsCard(RefundRequest refund) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor)),
      child: Column(
        children: [
          _row("Trip Price", "LKR ${refund.tripPrice.toStringAsFixed(2)}"),
          _row("Cancellation Rule",
              "${(refund.refundPercentage * 100).toInt()}% Refund"),
          const Divider(),
          _row("Refund Amount", "LKR ${refund.refundAmount.toStringAsFixed(2)}",
              isBold: true),
          const SizedBox(height: 16),
          _row("Reason", refund.reason.name),
          if (refund.otherReasonText != null &&
              refund.otherReasonText!.isNotEmpty)
            _row("Comment", refund.otherReasonText!),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontSize: isBold ? 18 : 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RefundRequest refund) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showRejectDialog(refund),
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red)),
            child: const Text("Reject"),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _handleApprove(refund),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Approve & Refund",
                    style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  void _handleApprove(RefundRequest refund) async {
    setState(() => _isLoading = true);
    String? stripeRefundId;

    try {
      // 1. Call Stripe API Directly
      if (refund.paymentIntentId != null &&
          refund.paymentIntentId!.isNotEmpty) {
        stripeRefundId = await StripeService.processRefund(
            refund.paymentIntentId!, refund.refundAmount);
      } else {
        debugPrint("Refund skipped: No payment ID");
      }

      final batch = FirebaseFirestore.instance.batch();

      // 1. Update Refund Request
      final refundRef =
          FirebaseFirestore.instance.collection('refunds').doc(refund.id);
      batch.update(refundRef, {
        'status': 'approved',
        'processingStatus': 'completed',
        'refundedAt': FieldValue.serverTimestamp(),
        'reviewNote': 'Refund processed via Admin Console (Direct API)',
      });

      // 2. Create RefundTransaction Record
      final transactionRef =
          FirebaseFirestore.instance.collection('refund_transactions').doc();
      final transaction = RefundTransaction(
          id: transactionRef.id,
          refundRequestId: refund.id,
          ticketId: refund.ticketId,
          userId: refund.userId,
          amount: refund.refundAmount,
          currency: 'lkr',
          stripePaymentIntentId: refund.paymentIntentId,
          stripeRefundId: stripeRefundId,
          status: RefundTransactionStatus.success,
          processedAt: DateTime.now());
      batch.set(transactionRef, transaction.toMap());

      // 3. Update Ticket Status (Cancel it)
      final ticketRef =
          FirebaseFirestore.instance.collection('tickets').doc(refund.ticketId);
      batch.update(ticketRef, {
        'status': 'cancelled',
        'cancellationReason': 'refunded',
      });

      // 4. Commit Batch
      await batch.commit();

      // 5. Notify User
      await NotificationService.createNotification(
          userId: refund.userId,
          title: "Refund Approved",
          body:
              "Your refund of LKR ${refund.refundAmount} has been approved and processed.",
          type: "refund_update",
          relatedId: refund.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Refund Processed Successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(RefundRequest refund) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Reject Refund"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Please select a valid reason for rejection."),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    items: const [
                      DropdownMenuItem(
                          value: "Policy Violation",
                          child: Text("Policy Violation")),
                      DropdownMenuItem(
                          value: "Already Used",
                          child: Text("Ticket Already Used")),
                      DropdownMenuItem(value: "Other", child: Text("Other")),
                    ],
                    onChanged: (v) {
                      // If using dropdown, state handling needed. Simple text field for now as per spec "Comment box".
                      // Spec says "Reason dropdown (mandatory)".
                      _rejectReasonController.text = v ?? "";
                    },
                    hint: const Text("Select Reason"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _rejectReasonController,
                    decoration: const InputDecoration(
                        labelText: "Comment", border: OutlineInputBorder()),
                    maxLines: 3,
                  )
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                    onPressed: () async {
                      if (_rejectReasonController.text.isEmpty) return;
                      Navigator.pop(ctx);
                      _handleReject(refund, _rejectReasonController.text);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Confirm Reject",
                        style: TextStyle(color: Colors.white)))
              ],
            ));
  }

  void _handleReject(RefundRequest refund, String reason) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('refunds')
          .doc(refund.id)
          .update({
        'status': 'rejected',
        'processingStatus':
            'failed', // or completed but status is rejected? Spec says REJECTED.
        'reviewNote': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.createNotification(
          userId: refund.userId,
          title: "Refund Rejected",
          body: "Your refund request was rejected: $reason",
          type: "refund_update",
          relatedId: refund.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
