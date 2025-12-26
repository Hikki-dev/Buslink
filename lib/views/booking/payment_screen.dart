import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // Import Stripe widgets

import '../../controllers/trip_controller.dart';
import '../../services/payment_service.dart';
import '../../utils/app_theme.dart';
import '../ticket/ticket_screen.dart';
import '../layout/desktop_navbar.dart';
import '../layout/app_footer.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _clientSecret;
  bool _isLoadingSecret = true;
  bool _isProcessing = false;
  CardFieldInputDetails? _cardDetails;

  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    _loadPaymentIntent();
  }

  Future<void> _loadPaymentIntent() async {
    try {
      final tripController =
          Provider.of<TripController>(context, listen: false);
      final trip = tripController.selectedTrip!;
      final seats = tripController.selectedSeats;
      final totalAmount = (trip.price * seats.length).toStringAsFixed(2);

      // Create Payment Intent immediately (Eager Load)
      final secret =
          await _paymentService.createPaymentIntent(totalAmount, "LKR");

      if (mounted) {
        setState(() {
          _clientSecret = secret;
          _isLoadingSecret = false;
        });
      }

      // If Mobile, Initialize Sheet immediately
      if (!kIsWeb) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: secret,
            merchantDisplayName: 'BusLink',
            style: ThemeMode.light,
            appearance: const PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(primary: Color(0xFFD32F2F)),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error loading payment: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Setup Error: ${e.toString()}")));
        setState(() => _isLoadingSecret = false);
      }
    }
  }

  Future<void> _handlePay() async {
    setState(() => _isProcessing = true);
    final user = Provider.of<User?>(context, listen: false);

    if (user == null) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to continue")));
      return;
    }

    try {
      if (kIsWeb) {
        // WEB: Confirm Payment using CardField data
        if (_cardDetails == null || _cardDetails?.complete == false) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Please enter complete card details.")));
          setState(() => _isProcessing = false);
          return;
        }

        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: _clientSecret!,
          data: const PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );
      } else {
        // MOBILE: Present Sheet
        await Stripe.instance.presentPaymentSheet();
      }

      // Success Handling
      _onPaymentSuccess();
    } on StripeException catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment Failed: ${e.error.localizedMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("Payment Execution Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onPaymentSuccess() async {
    final controller = Provider.of<TripController>(context, listen: false);
    final user = Provider.of<User?>(context, listen: false);

    // Record Booking in Firestore
    final bookingSuccess = await controller.processBooking(context, user!);

    if (bookingSuccess && mounted) {
      setState(() => _isProcessing = false);
      _showSuccessDialog();
    } else {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                "Payment Successful!",
                style: GoogleFonts.outfit(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Your ticket has been booked successfully.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const TicketScreen()),
                        (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("View Ticket",
                      style: GoogleFonts.outfit(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_clientSecret == null && _isLoadingSecret) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final controller = Provider.of<TripController>(context);
    final trip = controller.selectedTrip!;
    final seats = controller.selectedSeats;
    final totalAmount = trip.price * seats.length;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: isDesktop
          ? null
          : AppBar(
              title: Text("Secure Checkout",
                  style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold, color: Colors.black)),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
      body: Column(
        children: [
          if (isDesktop)
            DesktopNavBar(
                selectedIndex: -1, onTap: (i) => Navigator.pop(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: isDesktop
                        ? const EdgeInsets.symmetric(
                            vertical: 60, horizontal: 24)
                        : const EdgeInsets.all(24),
                    constraints: const BoxConstraints(minHeight: 600),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          children: [
                            if (isDesktop) ...[
                              Text("Secure Checkout",
                                  style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87)),
                              const SizedBox(height: 40),
                            ],
                            // Adaptive Layout
                            if (isDesktop) ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                      flex: 7,
                                      child: _buildOrderSummary(
                                          trip, seats, totalAmount)),
                                  const SizedBox(width: 48),
                                  Expanded(
                                      flex: 5,
                                      child: _buildPaymentSection(
                                          context, totalAmount)),
                                ],
                              ),
                            ] else ...[
                              _buildOrderSummary(trip, seats, totalAmount),
                              const SizedBox(height: 32),
                              _buildPaymentSection(context, totalAmount),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const AppFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(dynamic trip, List<int> seats, double totalAmount) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 4, height: 24, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Text("Order Summary",
                  style: GoogleFonts.outfit(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          _infoRow("Bus Operator", trip.operatorName),
          const Divider(height: 32),
          _infoRow("From", trip.fromCity),
          _infoRow("To", trip.toCity),
          const Divider(height: 32),
          _infoRow("Date",
              "${trip.departureTime.day}/${trip.departureTime.month}/${trip.departureTime.year}"),
          _infoRow("Time",
              "${trip.departureTime.hour}:${trip.departureTime.minute.toString().padLeft(2, '0')}"),
          const Divider(height: 32),
          _infoRow("Qty", "${seats.length}"),
          _infoRow("Price per seat", "LKR ${trip.price.toStringAsFixed(0)}"),
          _infoRow("Selected Seats", seats.join(", ")),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Amount",
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text("LKR ${totalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey.shade500)),
          Text(value,
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(BuildContext context, double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment Details",
            style:
                GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),

        // WEB: Styled CardField
        if (kIsWeb)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Card Information",
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600)),
                    const Icon(Icons.credit_card,
                        size: 24, color: AppTheme.primaryColor),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white),
                  alignment: Alignment.center,
                  child: CardField(
                    onCardChanged: (card) {
                      setState(() {
                        _cardDetails = card;
                      });
                    },
                    style: TextStyle(
                        fontFamily: GoogleFonts.inter().fontFamily,
                        fontSize: 16,
                        color: Colors.black),
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        hintText: "Card Details",
                        hintStyle: TextStyle(color: Colors.grey.shade400)),
                  ),
                ),
              ],
            ),
          )
        else
          // MOBILE: Visual Indicator of Stripe Sheet
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200)),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Credit / Debit Card",
                          style:
                              GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      Text("Click Pay to open Secure Checkout",
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle,
                    color: AppTheme.primaryColor, size: 20)
              ],
            ),
          ),

        const SizedBox(height: 32),
        _buildTermsAndConditions(),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePay,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shadowColor: Colors.black26,
                elevation: 8,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            child: _isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text("Pay LKR ${totalAmount.toStringAsFixed(0)}",
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Back",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade700)),
          ),
        ),
        const SizedBox(height: 24),
        _buildSecurityBadges(),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Terms & Conditions",
              style:
                  GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
              "By clicking 'Pay', you agree to BusLink's cancellation policy. Tickets can be cancelled up to 24 hours before departure for a 90% refund. No refunds for same-day cancellations.",
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade600, height: 1.5)),
          const SizedBox(height: 8),
          Text(
            "View full Terms of Service",
            style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline),
          )
        ],
      ),
    );
  }

  Widget _buildSecurityBadges() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.green.shade600),
            const SizedBox(width: 8),
            Text("SSL Encrypted Transaction",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _badge("Powered by Stripe"),
            _badge("PCI DSS Compliant"),
            _badge("3D Secure"),
          ],
        )
      ],
    );
  }

  Widget _badge(String text) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style:
                GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)));
  }
}
