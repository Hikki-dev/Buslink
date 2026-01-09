import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        .collection('refunds')
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
      final calc = _refundService.calculateRefundAmount(
          widget.ticket.totalAmount, widget.trip.departureTime);
      final refundPct = calc['percentage']!;
      final refundAmt = calc['refundAmount']!;
      final fee = calc['cancellationFee']!;

      final refundReq = RefundRequest(
        id: '', // Auto-generated
        ticketId: widget.ticket.ticketId,
        bookingId: widget.ticket.ticketId,
        tripId: widget.trip.id,
        userId: widget.ticket.userId,
        passengerName: widget.ticket.passengerName,
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
      );

      // Save to Firestore via Service
      await _refundService.createRefundRequest(refundReq);

      // Need ID for navigation, but createsRefundRequest creates it with auto-ID?
      // The service code used .doc(request.id).set(...) but passed '' as ID.
      // I should update Service to generate ID if empty or let Firestore do it.
      // Re-reading service: await _db.collection('refunds').doc(request.id).set(request.toMap());
      // If request.id is empty, it writes to document "" which overwrites. BAD.

      // FIX INLINE: Generate ID here.
      final newDocRef = FirebaseFirestore.instance.collection('refunds').doc();
      final fixedRequest = RefundRequest(
          id: newDocRef.id,
          ticketId: refundReq.ticketId,
          bookingId: refundReq.bookingId,
          userId: refundReq.userId,
          passengerName: refundReq.passengerName,
          tripId: refundReq.tripId,
          reason: refundReq.reason,
          otherReasonText: refundReq.otherReasonText,
          status: refundReq.status,
          tripPrice: refundReq.tripPrice,
          refundPercentage: refundReq.refundPercentage,
          refundAmount: refundReq.refundAmount,
          cancellationFee: refundReq.cancellationFee,
          createdAt: refundReq.createdAt,
          updatedAt: refundReq.updatedAt,
          requestedAt: refundReq.requestedAt,
          amountRequested: refundReq.amountRequested);

      await _refundService.createRefundRequest(fixedRequest);

      if (!mounted) return;

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => RefundStatusScreen(refundId: fixedRequest.id)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
      setState(() => _isLoading = false);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Summary
            _buildTripSummary(),
            const SizedBox(height: 24),

            // Rules
            const Text("Refund Policy",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ...RefundReason.values.map((r) => RadioListTile<RefundReason>(
                    title: Text(_formatReason(r)),
                    value: r,
                    groupValue: _selectedReason,
                    onChanged: (val) => setState(() => _selectedReason = val),
                    contentPadding: EdgeInsets.zero,
                  )),

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
                        color: AppTheme.primaryColor.withValues(alpha: 0.2))),
                child: Column(
                  children: [
                    _row("Trip Price",
                        "LKR ${widget.ticket.totalAmount.toStringAsFixed(2)}"),
                    _row("Refund Percentage", "${(refundPct * 100).toInt()}%"),
                    const Divider(),
                    _row("Refund Amount",
                        "LKR ${(widget.ticket.totalAmount * refundPct).toStringAsFixed(2)}",
                        isBold: true),
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
                  Text(widget.trip.fromCity,
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
                  Text(widget.trip.toCity,
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
              Text(widget.trip.duration),
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
            child: Text(refund,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false}) {
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
                  fontSize: isBold ? 18 : 14)),
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
