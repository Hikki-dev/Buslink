import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/refund_model.dart';
import '../../utils/app_theme.dart';

class RefundStatusScreen extends StatelessWidget {
  final String refundId;

  const RefundStatusScreen({super.key, required this.refundId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Refund Status"),
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('refunds')
            .doc(refundId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Refund request not found"));
          }

          final refund = RefundRequest.fromFirestore(snapshot.data!);

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildStatusBadge(refund.status),
                const SizedBox(height: 24),
                if (refund.status == RefundStatus.rejected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        const Text("Refund Rejected",
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(refund.reviewNote ?? "No reason provided",
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10)
                      ]),
                  child: Column(
                    children: [
                      _row("Refund Amount",
                          "LKR ${refund.refundAmount.toStringAsFixed(2)}",
                          isBold: true, color: AppTheme.primaryColor),
                      const Divider(),
                      _row("Cancellation Fee",
                          "LKR ${refund.cancellationFee.toStringAsFixed(2)}"),
                      _row("Original Trip Price",
                          "LKR ${refund.tripPrice.toStringAsFixed(2)}"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (refund.status == RefundStatus.approved)
                  const Text("Processing time: 5–7 working days",
                      style: TextStyle(color: Colors.grey)),
                if (refund.status == RefundStatus.pending)
                  const Text("Your request is under review.",
                      style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(RefundStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case RefundStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle;
        text = "APPROVED";
        break;
      case RefundStatus.processed:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        text = "PROCESSED";
        break;
      case RefundStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = "REJECTED";
        break;
      case RefundStatus.failed:
        color = Colors.redAccent;
        icon = Icons.error_outline;
        text = "FAILED";
        break;
      case RefundStatus.pending:
      default:
        color = Colors.orange;
        icon = Icons.hourglass_top;
        text = "PENDING";
        break;
    }

    return Column(
      children: [
        Icon(icon, size: 64, color: color),
        const SizedBox(height: 16),
        Text(text,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 1.5))
      ],
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 20 : 16,
                  color: color)),
        ],
      ),
    );
  }
}
