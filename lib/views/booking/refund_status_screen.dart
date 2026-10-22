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
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "We could not load this refund.\nPlease check your internet and try again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
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
                const SizedBox(height: 20),
                RefundProgress(status: refund.status),
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
                      style: TextStyle(color: Color(0xFF616161), fontSize: 16)),
                if (refund.status == RefundStatus.pending)
                  const Text("Your request is under review.",
                      style: TextStyle(color: Color(0xFF616161), fontSize: 16)),
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
          Text(label,
              style: const TextStyle(color: Color(0xFF616161), fontSize: 16)),
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

/// Three plain steps so people can see where their refund is:
/// Sent -> In review -> Decision.
class RefundProgress extends StatelessWidget {
  final RefundStatus status;
  const RefundProgress({super.key, required this.status});

  /// 0 = sent, 1 = in review (current), 2 = decided.
  static int stepFor(RefundStatus s) => s == RefundStatus.pending ? 1 : 2;

  @override
  Widget build(BuildContext context) {
    final step = stepFor(status);
    final rejected =
        status == RefundStatus.rejected || status == RefundStatus.failed;
    final decisionLabel = rejected ? 'Rejected' : 'Approved';
    final labels = [
      'Sent',
      'In review',
      step == 2 ? decisionLabel : 'Decision'
    ];

    return Semantics(
      label: 'Refund progress: ${labels[step]}',
      child: Row(
        children: [
          for (var i = 0; i < 3; i++) ...[
            _Dot(
              label: labels[i],
              done: i < step || (i == 2 && step == 2),
              current: i == step && step < 2,
              failed: i == 2 && rejected,
            ),
            if (i < 2)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.only(bottom: 22),
                  color:
                      i < step ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final bool failed;
  const _Dot({
    required this.label,
    required this.done,
    required this.current,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final color = failed ? Colors.red.shade700 : AppTheme.primaryColor;
    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color : Colors.white,
              border: Border.all(
                color: done || current ? color : Colors.grey.shade400,
                width: 3,
              ),
            ),
            child: done
                ? Icon(failed ? Icons.close : Icons.check,
                    size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: done || current ? FontWeight.w700 : FontWeight.w400,
              color: done || current ? color : const Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}
