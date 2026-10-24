import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../../../models/refund_model.dart';
import '../../../utils/bl_colors.dart';
import '../../widgets/bl_widgets.dart';
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const BlHeader(title: 'Refund Details'),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('refunds')
                  .doc(widget.refundId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: BL.crimson));
                }
                final refund = RefundRequest.fromFirestore(snapshot.data!);
                final pending = refund.status == RefundStatus.pending;
                final approved = refund.status == RefundStatus.approved ||
                    refund.status == RefundStatus.processed;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(refund.passengerName,
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: pending
                                      ? const Color(0xFFFFF1DB)
                                      : (approved
                                          ? const Color(0xFFDDF1E3)
                                          : const Color(0xFFFBE0DC)),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                    'Refund Status: ${pending ? 'Pending' : approved ? 'Approved' : 'Rejected'}',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: pending
                                            ? const Color(0xFF7A4300)
                                            : (approved
                                                ? const Color(0xFF14532D)
                                                : const Color(0xFF7F1D14)))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildDetailsCard(refund),
                          const SizedBox(height: 24),
                          if (pending) _buildActionButtons(refund),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(RefundRequest refund) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BL.hairline)),
      child: Column(
        children: [
          // Email with copy icon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Email", style: TextStyle()),
                const SizedBox(width: 16),
                Expanded(
                  child: FutureBuilder<DocumentSnapshot?>(
                    future: (refund.email == null ||
                                refund.email!.isEmpty ||
                                refund.email == 'N/A' ||
                                refund.email == 'null') &&
                            refund.userId.isNotEmpty &&
                            refund.userId != 'guest'
                        ? FirebaseFirestore.instance
                            .collection('users')
                            .doc(refund.userId)
                            .get()
                        : Future<DocumentSnapshot?>.value(null),
                    builder: (context, userSnap) {
                      String? email = refund.email;
                      if (email == null ||
                          email.isEmpty ||
                          email == 'N/A' ||
                          email == 'null') {
                        email = refund.userData?['email']?.toString();
                      }
                      if ((email == null ||
                              email.isEmpty ||
                              email == 'N/A' ||
                              email == 'null') &&
                          userSnap.hasData &&
                          userSnap.data!.exists) {
                        email = (userSnap.data!.data()
                            as Map<String, dynamic>)['email'];
                      }

                      final displayEmail = (email != null &&
                              email.isNotEmpty &&
                              email != 'N/A' &&
                              email != 'null')
                          ? email
                          : 'N/A';

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              displayEmail,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          if (displayEmail != 'N/A') ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: displayEmail));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Email copied to clipboard'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy email',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          _row("Trip Price", "LKR ${refund.tripPrice.toStringAsFixed(2)}"),
          _row('Cancellation Rule',
              "${(refund.refundPercentage * 100).toInt()}% Refund"),
          const Divider(),
          _row('Refund Amount', "LKR ${refund.refundAmount.toStringAsFixed(2)}",
              isBold: true),
          const SizedBox(height: 16),
          _row("Reason", refund.reason.name),
          if (refund.otherReasonText != null &&
              refund.otherReasonText!.isNotEmpty)
            _row('Comment', refund.otherReasonText!),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 17, color: BL.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
                    color: isBold ? BL.crimson : BL.ink,
                    fontSize: isBold ? 26 : 17)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(RefundRequest refund) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          height: 56,
          child: OutlinedButton(
            onPressed: () => _showRejectDialog(refund),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              foregroundColor: const Color(0xFFA3281C),
              side: const BorderSide(color: Color(0xFFA3281C), width: 2),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            child: const Text('Reject'),
          ),
        ),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _isLoading ? null : () => _handleApprove(refund),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              backgroundColor: BL.success,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Approve Refund'),
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
        'status': 'refunded',
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
          SnackBar(content: Text('Refund Processed Successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRejectDialog(RefundRequest refund) {
    _rejectReasonController.clear();
    String? reason;
    final comment = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (ctx, setD) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text('Reject Refund',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                content: SizedBox(
                  width: 440,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Are you sure you want to reject this refund?',
                          style: TextStyle(fontSize: 16, color: BL.muted)),
                      const SizedBox(height: 16),
                      const Text('Select Reason *',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: reason,
                        isExpanded: true,
                        hint: const Text('Select Reason'),
                        items: const [
                          DropdownMenuItem(
                              value: 'Policy Violation',
                              child: Text('Policy Violation')),
                          DropdownMenuItem(
                              value: 'Already Used',
                              child: Text('Already Used')),
                          DropdownMenuItem(
                              value: 'Ticket Used', child: Text('Ticket Used')),
                          DropdownMenuItem(
                              value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setD(() => reason = v),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Comment',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: comment,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Comment box',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: reason == null
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              final c = comment.text.trim();
                              _handleReject(
                                  refund, c.isEmpty ? reason! : '$reason: $c');
                            },
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFA3281C)),
                      child: const Text('Confirm Reject')),
                ],
              ),
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
