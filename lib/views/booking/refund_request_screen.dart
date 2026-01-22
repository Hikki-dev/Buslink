import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../models/refund_model.dart';

import '../../services/refund_service.dart'; // Added
import '../../utils/app_theme.dart';
import 'refund_status_screen.dart';

class RefundRequestScreen extends StatefulWidget {
  final Ticket ticket;
  final Trip trip;

  const RefundRequestScreen(
      {super.key, required this.ticket, required this.trip});

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  RefundReason? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isLoading = false;

  final RefundService _refundService = RefundService();
  double _refundPercentage = 0.0;
  bool _isEligible = false;
  String _eligibilityReason = '';

  @override
  void initState() {
    super.initState();
    _checkExistingRefund();
    _calculateRefundDetails();
  }

  void _calculateRefundDetails() async {
    // Check Eligibility
    final eligibility = await _refundService.checkRefundEligibility(
        widget.trip.id, widget.trip.departureTime);

    if (mounted) {
      setState(() {
        _isEligible = eligibility['eligible'] as bool;
        _eligibilityReason = eligibility['reason'] ?? '';
      });
    }

    // Calculate Amounts
    final calc = _refundService.calculateRefundAmount(
        widget.ticket.totalAmount, widget.trip.departureTime);

    if (mounted) {
      setState(() {
        _refundPercentage = calc['percentage']!;
      });
    }
  }

  Future<void> _checkExistingRefund() async {
    final q = await FirebaseFirestore.instance
        .collection('Refunds')
        .where('ticketId', isEqualTo: widget.ticket.ticketId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => RefundStatusScreen(refundId: q.docs.first.id)));
      });
    }
  }

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  void _submitRefund() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a reason")));
      return;
    }
    if (_selectedReason == RefundReason.other &&
        _otherReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please specify the reason")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint(
          "DEBUG REFUND: Ticket User: ${widget.ticket.userId}, Auth User: ${currentUser?.uid}");

      if (currentUser != null && widget.ticket.userId != currentUser.uid) {
        debugPrint(
            "WARNING: Mismatch in IDs may cause permission error if not Admin.");
      }

      // 1. Strict Duplicate Check (Moved inside try-catch with timeout)
      final existingQuery = await FirebaseFirestore.instance
          .collection('Refunds')
          .where('ticketId', isEqualTo: widget.ticket.ticketId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (existingQuery.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("A refund request already exists.")));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    RefundStatusScreen(refundId: existingQuery.docs.first.id)));
        return;
      }

      final calc = _refundService.calculateRefundAmount(
          widget.ticket.totalAmount, widget.trip.departureTime);
      final refundPct = calc['percentage']!;
      final refundAmt = calc['refundAmount']!;
      final fee = calc['cancellationFee']!;

      // Generate ID first
      final newDocRef = FirebaseFirestore.instance.collection('Refunds').doc();

      final refundReq = RefundRequest(
        id: newDocRef.id,
        ticketId: widget.ticket.ticketId,
        bookingId: widget.ticket.ticketId,
        tripId: widget.trip.id,
        userId: widget.ticket.userId,
        passengerName: widget.ticket.passengerName,
        email: widget.ticket.passengerEmail ??
            currentUser?.email, // FIXED: Include email
        reason: _selectedReason!,
        otherReasonText: _otherReasonController.text.trim(),
        status: RefundStatus.pending,
        tripPrice: widget.ticket.totalAmount,
        refundPercentage: refundPct,
        refundAmount: refundAmt,
        cancellationFee: fee,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        requestedAt: DateTime.now(),
        amountRequested: refundAmt,
        paymentIntentId: widget.ticket.paymentIntentId, // Ensure this is passed
      );

      // Add timeout to creation as well
      await _refundService
          .createRefundRequest(refundReq)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      // Show Success Message as requested
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Refund details submitted. Check status for updates."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Navigate to Status Screen
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => RefundStatusScreen(refundId: refundReq.id)));
    } catch (e) {
      if (mounted) {
        debugPrint("Refund Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Submission failed: $e"),
            backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Used cached values from state
    final refundPct = _refundPercentage;
    final isEligible = _isEligible;
    final reasonText = _eligibilityReason.isNotEmpty
        ? _eligibilityReason
        : "Refund unavailable (less than 6 hours before departure).";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Refund"),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: const BackButton(),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Summary
                _buildTripSummary(),
                const SizedBox(height: 24),

                // Rules
                const Text("Refund Policy",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                _buildPolicyTable(),
                const SizedBox(height: 24),

                if (!isEligible)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reasonText)) // Dynamic Reason
                    ]),
                  ),

                if (isEligible) ...[
                  const Text("Select Reason",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  RadioGroup<RefundReason>(
                    groupValue: _selectedReason,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedReason = val);
                    },
                    child: Column(
                      children: RefundReason.values
                          .map((r) => RadioListTile<RefundReason>(
                                title: Text(_formatReason(r)),
                                value: r,
                                contentPadding: EdgeInsets.zero,
                                // groupValue and onChanged are managed by RadioGroup ancestor
                              ))
                          .toList(),
                    ),
                  ),

                  if (_selectedReason == RefundReason.other)
                    TextField(
                      controller: _otherReasonController,
                      decoration: const InputDecoration(
                        labelText: "Please specify",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),

                  const SizedBox(height: 24),

                  // Calculation Preview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.primaryColor.withValues(alpha: 0.2))),
                    child: Column(
                      children: [
                        _row("Trip Price",
                            "LKR ${widget.ticket.totalAmount.toStringAsFixed(2)}"),
                        _row("Cancellation Fee",
                            "LKR ${(widget.ticket.totalAmount * (1 - refundPct)).toStringAsFixed(2)}",
                            color: Colors.red.shade300),
                        const Divider(height: 32),
                        Column(
                          children: [
                            const Text("YOU RECEIVE",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(
                              "LKR ${(widget.ticket.totalAmount * refundPct).toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRefund,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Request",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: const Offset(0, 2))
          ]),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("From",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(widget.trip.originCity,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("To",
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(widget.trip.destinationCity,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DateFormat('MMM d, yyyy - h:mm a')
                  .format(widget.trip.departureTime)),
              Text(
                  "${widget.trip.arrivalTime.difference(widget.trip.departureTime).inHours}h ${widget.trip.arrivalTime.difference(widget.trip.departureTime).inMinutes % 60}m"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPolicyTable() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _policyRow("> 24 Hours", "90% Refund", Colors.green),
          const Divider(),
          _policyRow("6 - 24 Hours", "50% Refund", Colors.orange),
          const Divider(),
          _policyRow("< 6 Hours", "No Refund", Colors.red),
        ],
      ),
    );
  }

  Widget _policyRow(String time, String refund, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  color == Colors.green
                      ? Icons.check_circle
                      : (color == Colors.orange ? Icons.warning : Icons.cancel),
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(refund,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: isBold ? 18 : 14,
                  color: color)),
        ],
      ),
    );
  }

  String _formatReason(RefundReason r) {
    switch (r) {
      case RefundReason.changeOfPlans:
        return "Change of Plans";
      case RefundReason.personalEmergency:
        return "Personal Emergency";
      case RefundReason.tripDelay:
        return "Trip Delayed";
      case RefundReason.tripCancelledByOperator:
        return "Cancelled by Operator";
      case RefundReason.bookingMistake:
        return "Booking Mistake";
      case RefundReason.seatOrBusIssue:
        return "Seat/Bus Issue";
      case RefundReason.other:
        return "Other";
    }
  }
}
