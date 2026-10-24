import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../models/refund_model.dart';

import '../../services/refund_service.dart'; // Added
import '../../utils/bl_colors.dart';
import '../home/home_sections.dart' show cityPhoto;
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
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint(
          "DEBUG REFUND: Ticket User: ${widget.ticket.userId}, Auth User: ${currentUser?.uid}");

      if (currentUser != null && widget.ticket.userId != currentUser.uid) {
        debugPrint(
            "WARNING: Mismatch in IDs may cause permission error if not Admin.");
      }

      // 1. Strict Duplicate Check (Moved inside try-catch with timeout)
      final existingQuery = await FirebaseFirestore.instance
          .collection('refunds')
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

      // 2. Resolve Robust User Data (Profile > Ticket > Auth)
      final authUid = currentUser?.uid;
      Map<String, dynamic> resolvedUserData = widget.ticket.userData ?? {};

      // Only fetch profile if we have a valid UID to check against
      final String? lookupId =
          (widget.ticket.userId != 'guest' && widget.ticket.userId.isNotEmpty)
              ? widget.ticket.userId
              : authUid;

      if (lookupId != null && lookupId != 'guest') {
        try {
          final profileDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(lookupId)
              .get();
          if (profileDoc.exists) {
            resolvedUserData = profileDoc.data()!;
          }
        } catch (e) {
          debugPrint(
              "Warning: Could not fetch profile for refund ($lookupId): $e");
        }
      }

      final String pName = resolvedUserData['displayName'] ??
          resolvedUserData['name'] ??
          widget.ticket.passengerName;
      final String pEmail = resolvedUserData['email'] ??
          widget.ticket.passengerEmail ??
          currentUser?.email ??
          '';
      final String pPhone = resolvedUserData['phoneNumber'] ??
          resolvedUserData['phone'] ??
          widget.ticket.passengerPhone ??
          'N/A';

      // Generate ID first
      final newDocRef = FirebaseFirestore.instance.collection('refunds').doc();

      final refundReq = RefundRequest(
        id: newDocRef.id,
        ticketId: widget.ticket.ticketId,
        bookingId: widget.ticket.ticketId,
        tripId: widget.trip.id,
        userId: authUid ?? widget.ticket.userId, // ESSENTIAL for security rules
        passengerName: pName,
        passengerPhone: pPhone,
        email: pEmail,
        userData: {
          'name': pName,
          'email': pEmail,
          'phone': pPhone,
          'originalUserId': widget.ticket.userId, // Keep for audit
        },
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
        paymentIntentId: widget.ticket.paymentIntentId,
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
    final refundPct = _refundPercentage;
    final isEligible = _isEligible;
    final reasonText = _eligibilityReason.isNotEmpty
        ? _eligibilityReason
        : "Refund unavailable (less than 6 hours before departure).";
    final paid = widget.ticket.totalAmount;
    final fmt = NumberFormat('#,###');
    final trip = widget.trip;
    final seats = (widget.ticket.seatNumbers.toList()..sort()).join(', ');

    final summary = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: BL.hairline),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(cityPhoto(trip.destinationCity),
                width: 64, height: 64, fit: BoxFit.cover),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${trip.originCity} to ${trip.destinationCity}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                    '${DateFormat('EEE d MMM').format(trip.departureTime)} · Seats $seats',
                    style: const TextStyle(fontSize: 16, color: BL.muted)),
                Text('Paid LKR ${fmt.format(paid)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );

    final policy = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F3F4),
          borderRadius: BorderRadius.circular(14)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Refund Policy',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
              'The earlier you cancel, the more you get back. More than 24 hours before the bus leaves: 90% back. Between 6 and 24 hours: 50% back. Less than 6 hours: no refund.',
              style: TextStyle(
                  fontSize: 16, height: 1.45, color: Color(0xFF3A2F31))),
        ],
      ),
    );

    final form = <Widget>[
      if (!isEligible)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: const Color(0xFFFBE0DC),
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.block, color: Color(0xFF7F1D14)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(reasonText,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7F1D14)))),
          ]),
        ),
      if (isEligible) ...[
        const Text('Select Reason',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<RefundReason>(
          initialValue: _selectedReason,
          isExpanded: true,
          hint: const Text('Choose a reason'),
          icon: const Icon(Icons.expand_more),
          style: const TextStyle(fontSize: 17, color: BL.ink),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BL.border, width: 1.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: BL.border, width: 1.5)),
          ),
          items: [
            for (final r in RefundReason.values)
              DropdownMenuItem(value: r, child: Text(_formatReason(r))),
          ],
          onChanged: (v) => setState(() => _selectedReason = v),
        ),
        if (_selectedReason == RefundReason.other) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _otherReasonController,
            maxLines: 2,
            style: const TextStyle(fontSize: 17),
            decoration: InputDecoration(
              labelText: 'Please tell us more',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEEEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5383B), width: 1.5),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text('YOU RECEIVE',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8)),
              ),
              Text('LKR ${fmt.format(paid * refundPct)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: BL.crimson)),
            ],
          ),
        ),
      ],
    ];

    final submit = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: (_isLoading || !isEligible) ? null : _submitRefund,
            style: FilledButton.styleFrom(
              backgroundColor: BL.crimson,
              disabledBackgroundColor: const Color(0xFFE3DADB),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 19,
                  fontWeight: FontWeight.w800),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Submit Request'),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Processing time: 5–7 working days',
            style: TextStyle(fontSize: 15, color: BL.muted)),
      ],
    );

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
                const Text('Request Refund',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      summary,
                      const SizedBox(height: 16),
                      policy,
                      const SizedBox(height: 16),
                      ...form,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 14, 16, 14 + MediaQuery.paddingOf(context).bottom),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: BL.hairline))),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: submit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatReason(RefundReason r) {
    switch (r) {
      case RefundReason.changeOfPlans:
        return "Change of plans";
      case RefundReason.personalEmergency:
        return "Personal emergency";
      case RefundReason.tripDelay:
        return "The trip was delayed";
      case RefundReason.tripCancelledByOperator:
        return "Cancelled by the operator";
      case RefundReason.bookingMistake:
        return "Booking mistake";
      case RefundReason.seatOrBusIssue:
        return "Seat or bus problem";
      case RefundReason.other:
        return "Something else";
    }
  }
}
