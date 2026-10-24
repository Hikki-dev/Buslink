import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/refund_model.dart';
import 'package:intl/intl.dart';
import '../../utils/bl_colors.dart';
import '../customer_main_screen.dart';
import '../support/support_screen.dart';
import '../widgets/bl_widgets.dart';

class RefundStatusScreen extends StatelessWidget {
  final String refundId;

  const RefundStatusScreen({super.key, required this.refundId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: BL.crimson,
            padding: EdgeInsets.fromLTRB(
                8, MediaQuery.paddingOf(context).top + 4, 8, 16),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Go back',
                  onPressed: () => Navigator.maybePop(context),
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                ),
                const SizedBox(width: 4),
                const Text('Refund Status',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('refunds')
                  .doc(refundId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: BL.crimson));
                }
                if (snapshot.hasError) {
                  return _note(
                      'We could not load this refund. Please check your internet and try again.');
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _note(
                      'Refund request not found. The link may be old. Open My Trips to see your refunds.');
                }
                return _Body(
                    refund: RefundRequest.fromFirestore(snapshot.data!));
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _note(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: BL.muted)),
        ),
      );
}

class _Body extends StatelessWidget {
  final RefundRequest refund;
  const _Body({required this.refund});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final status = refund.status;
    final rejected =
        status == RefundStatus.rejected || status == RefundStatus.failed;
    final pending = status == RefundStatus.pending;

    final Color bg = rejected
        ? const Color(0xFFFBE0DC)
        : (pending ? const Color(0xFFFFF1DB) : const Color(0xFFDDF1E3));
    final Color fg = rejected
        ? const Color(0xFF7F1D14)
        : (pending ? const Color(0xFF7A4300) : const Color(0xFF14532D));
    final headline = rejected
        ? 'Refund Rejected'
        : pending
            ? 'Your request is under review.'
            : (status == RefundStatus.processed
                ? 'Your refund has been paid out.'
                : 'Your refund was approved.');
    final icon = rejected
        ? Icons.block
        : (pending ? Icons.schedule : Icons.check_circle_outline);

    Widget row(String l, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Text(l, style: const TextStyle(fontSize: 17, color: BL.muted)),
              const Spacer(),
              Text(v,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 28, color: fg),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(headline,
                              style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: fg)),
                        ),
                      ],
                    ),
                    if (rejected) ...[
                      const SizedBox(height: 14),
                      Text('REASON',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: fg)),
                      const SizedBox(height: 2),
                      Text(
                          (refund.reviewNote ?? '').trim().isEmpty
                              ? 'No reason provided'
                              : refund.reviewNote!,
                          style:
                              TextStyle(fontSize: 18, height: 1.4, color: fg)),
                    ] else ...[
                      const SizedBox(height: 16),
                      RefundProgress(status: status),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (rejected) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: BL.hairline),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(
                          fontSize: 17, height: 1.5, color: Color(0xFF3A2F31)),
                      children: [
                        const TextSpan(
                            text:
                                'If you think this is a mistake, contact support and quote your ticket ID '),
                        TextSpan(
                            text: refund.ticketId.length > 8
                                ? refund.ticketId.substring(0, 8)
                                : refund.ticketId,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: BL.ink)),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                BlPrimaryButton(
                  label: 'Contact support',
                  color: BL.crimson,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SupportScreen())),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: BL.hairline),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      row('Original Trip Price',
                          'LKR ${fmt.format(refund.tripPrice)}'),
                      row('Cancellation Fee',
                          '− LKR ${fmt.format(refund.cancellationFee)}'),
                      const Divider(height: 22, color: BL.hairline),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text('Refund Amount',
                              style: TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          const Spacer(),
                          Text('LKR ${fmt.format(refund.refundAmount)}',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: BL.crimson)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Processing time: 5–7 working days',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: BL.muted)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) =>
                              const CustomerMainScreen(initialIndex: 1)),
                      (r) => false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BL.crimson,
                    side: const BorderSide(color: BL.crimson, width: 2),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18,
                        fontWeight: FontWeight.w800),
                  ),
                  child: const Text('Back to My Trips'),
                ),
              ),
            ],
          ),
        ),
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
                  color: i < step ? BL.crimson : Colors.grey.shade300,
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
    final color = failed ? Colors.red.shade700 : BL.crimson;
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
